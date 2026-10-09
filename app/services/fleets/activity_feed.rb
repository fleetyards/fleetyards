# frozen_string_literal: true

module Fleets
  # What happened in a fleet lately, read off the records themselves rather than
  # a log: every source is a timestamp a record already carries, so the feed has
  # history from the start and never disagrees with the lists it summarises.
  #
  # The caller hands in the relations the reader may see. Narrowing them is the
  # job of the policies each list already goes through, and doing it here would
  # be a second copy of those rules to keep in step.
  class ActivityFeed
    CATEGORIES = %w[members events contracts inventory].freeze

    KINDS = {
      "member_joined" => "members",
      "event_published" => "events",
      "event_cancelled" => "events",
      "contract_published" => "contracts",
      "contract_claimed" => "contracts",
      "contract_fulfilled" => "contracts",
      "inventory_transfer_completed" => "inventory",
      "inventory_item_deposited" => "inventory",
      "inventory_item_withdrawn" => "inventory"
    }.freeze

    AVATAR = {avatar_attachment: :blob}.freeze

    DEFAULT_LIMIT = 20
    MAX_LIMIT = 50

    Entry = Data.define(:kind, :record, :occurred_at, :actor, :involves_viewer, :inventory) do
      def id = "#{kind}-#{record.id}"

      def category = KINDS.fetch(kind)
    end

    def initialize(user:, memberships: nil, events: nil, contracts: nil, inventories: nil)
      @user = user
      @memberships = memberships
      @events = events
      @contracts = contracts
      @inventories = inventories
    end

    def entries(category: nil, limit: DEFAULT_LIMIT)
      @limit = limit.to_i.clamp(1, MAX_LIMIT)

      sources = {
        "members" => -> { member_entries },
        "events" => -> { event_entries },
        "contracts" => -> { contract_entries },
        "inventory" => -> { inventory_entries }
      }
      sources = sources.slice(category) if category.present?

      sources.values.flat_map(&:call)
        .sort_by { |entry| [-entry.occurred_at.to_f, entry.id] }
        .first(@limit)
    end

    private def member_entries
      return [] if @memberships.nil?

      latest(@memberships.where.not(accepted_at: nil).includes(user: AVATAR), :accepted_at).map do |membership|
        entry("member_joined", membership, membership.accepted_at,
          actor: membership.user, involves_viewer: membership.user_id == @user.id)
      end
    end

    private def event_entries
      return [] if @events.nil?

      published = latest(@events.where.not(published_at: nil).includes(created_by: AVATAR), :published_at)
        .map do |event|
          entry("event_published", event, event.published_at,
            actor: event.created_by, involves_viewer: event.created_by_id == @user.id)
        end
      cancelled = latest(@events.where(status: "cancelled").where.not(cancelled_at: nil), :cancelled_at)
        .map { |event| entry("event_cancelled", event, event.cancelled_at, involves_viewer: event.created_by_id == @user.id) }

      published + cancelled
    end

    private def contract_entries
      return [] if @contracts.nil?

      worked = FleetContractAssignment.where(user_id: @user.id, aasm_state: "accepted", fleet_contract_id: @contracts.select(:id))
        .pluck(:fleet_contract_id).to_set

      %w[published claimed fulfilled].flat_map do |step|
        column = :"#{step}_at"
        # Only the posting is told as somebody's doing, so only it needs them.
        relation = @contracts.where.not(column => nil)
        relation = relation.includes(created_by: AVATAR) if step == "published"

        latest(relation, column).map do |contract|
          entry("contract_#{step}", contract, contract.public_send(column),
            actor: (step == "published") ? contract.created_by : nil,
            involves_viewer: contract.created_by_id == @user.id || worked.include?(contract.id))
        end
      end
    end

    private def inventory_entries
      return [] if @inventories.nil?

      inventories = @inventories.to_a.index_by(&:id)
      return [] if inventories.empty?

      transfers = InventoryTransfer.completed
        .where(source_fleet_inventory_id: inventories.keys)
        .or(InventoryTransfer.completed.where(destination_fleet_inventory_id: inventories.keys))
        .includes(initiated_by: AVATAR)
      transfer_entries = latest(transfers, :completed_at).map do |transfer|
        inventory = inventories[transfer.destination_fleet_inventory_id] || inventories[transfer.source_fleet_inventory_id]
        entry("inventory_transfer_completed", transfer, transfer.completed_at,
          actor: transfer.initiated_by, inventory:,
          involves_viewer: inventory.managed_by == @user.id ||
            [transfer.initiated_by_id, transfer.recipient_id, transfer.fleet_contract_contributor_id].include?(@user.id))
      end

      # A transfer's own items arrive with it, and are told by the transfer entry.
      items = FleetInventoryItem.where(fleet_inventory_id: inventories.keys, inventory_transfer_id: nil)
        .includes(added_by_user: AVATAR)
      item_entries = latest(items, :created_at).map do |item|
        inventory = inventories[item.fleet_inventory_id]
        entry(item.withdrawal? ? "inventory_item_withdrawn" : "inventory_item_deposited", item, item.created_at,
          actor: item.added_by_user, inventory:,
          involves_viewer: inventory.managed_by == @user.id || [item.added_by, item.member_id].include?(@user.id))
      end

      transfer_entries + item_entries
    end

    # Each source is cut to the page before the merge, so no query reads more of
    # a fleet's history than the page could show.
    private def latest(relation, column)
      relation.reorder(relation.arel_table[column].desc).limit(@limit)
    end

    private def entry(kind, record, occurred_at, actor: nil, involves_viewer: false, inventory: nil)
      Entry.new(kind:, record:, occurred_at:, actor:, involves_viewer:, inventory:)
    end
  end
end
