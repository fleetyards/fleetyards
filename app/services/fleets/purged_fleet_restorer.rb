# frozen_string_literal: true

module Fleets
  # Rebuilds a hard-deleted ("purged") fleet from its PaperTrail destroy
  # versions. Best effort: only versioned models are restored (fleet, roles,
  # memberships, inventories, inventory items). ActiveStorage attachments,
  # invite urls and fleet vehicles are not recoverable; fleet vehicles
  # regenerate from member hangars once memberships are restored.
  class PurgedFleetRestorer
    class FleetStillExists < StandardError; end

    class NothingToRestore < StandardError; end

    class FidTaken < StandardError; end

    MEMBERSHIP_COLUMNS = %w[
      aasm_state accepted_at invited_at requested_at declined_at primary
      hide_ships ships_filter hangar_group_id invited_by used_invite_token verified
    ].freeze

    INVENTORY_COLUMNS = %w[description location visibility managed_by slug].freeze

    INVENTORY_ITEM_COLUMNS = %w[
      item_type item_id quantity name notes added_by member_id category entry_type quality unit
    ].freeze

    def initialize(fleet_id)
      @fleet_id = fleet_id
    end

    def call
      raise FleetStillExists if Fleet.unscoped.exists?(id: @fleet_id)

      version = latest_destroy_version("Fleet", @fleet_id)
      raise NothingToRestore if version.nil?

      ActiveRecord::Base.transaction do
        fleet = version.reify
        raise FidTaken if fleet.fid.present? && Fleet.kept.where("LOWER(fid) = ?", fleet.fid.downcase).exists?

        fleet.save!(validate: false)

        role_map = restore_roles(fleet)
        restore_memberships(fleet, role_map)
        inventory_map = restore_inventories(fleet)
        restore_inventory_items(inventory_map)

        fleet
      end
    end

    private

    def latest_destroy_version(item_type, item_id)
      PaperTrail::Version
        .where(item_type:, item_id:, event: "destroy")
        .order(created_at: :desc)
        .first
    end

    def child_destroy_versions(item_type, foreign_key, value)
      PaperTrail::Version
        .where(item_type:, event: "destroy")
        .where("object ->> ? = ?", foreign_key, value.to_s)
    end

    # Returns a map of the old fleet_role_id => restored FleetRole, keyed by name
    # so memberships can be re-linked. setup_default_roles! (run on fleet save)
    # already recreated the standard roles, so custom roles are merged in.
    def restore_roles(fleet)
      map = {}

      child_destroy_versions("FleetRole", "fleet_id", fleet.id).find_each do |version|
        role = version.reify
        restored = fleet.fleet_roles.find_or_create_by!(name: role.name) do |new_role|
          new_role.resource_access = role.resource_access
          new_role.permanent = role.permanent
        end
        map[version.item_id] = restored
      end

      map
    end

    # Role assignment is best effort: FleetRole nullifies its memberships when
    # it is destroyed (roles cascade before memberships), so the destroy
    # snapshot's fleet_role_id may already be nil. When the old role cannot be
    # mapped, the member falls back to the default member role and the fleet
    # owner is re-granted admin by setup_admin_user.
    def restore_memberships(fleet, role_map)
      child_destroy_versions("FleetMembership", "fleet_id", fleet.id).find_each do |version|
        membership = version.reify
        record = fleet.fleet_memberships.find_or_initialize_by(user_id: membership.user_id)
        record.assign_attributes(membership.attributes.slice(*MEMBERSHIP_COLUMNS))
        record.fleet_role = role_map[membership.fleet_role_id] || fleet.default_member_role
        record.discarded_at = nil
        record.save!(validate: false)
      end
    end

    def restore_inventories(fleet)
      map = {}

      child_destroy_versions("FleetInventory", "fleet_id", fleet.id).find_each do |version|
        inventory = version.reify
        restored = fleet.fleet_inventories.find_or_create_by!(name: inventory.name) do |new_inventory|
          new_inventory.assign_attributes(inventory.attributes.slice(*INVENTORY_COLUMNS))
        end
        map[version.item_id] = restored
      end

      map
    end

    def restore_inventory_items(inventory_map)
      return if inventory_map.empty?

      PaperTrail::Version
        .where(item_type: "FleetInventoryItem", event: "destroy")
        .where("object ->> 'fleet_inventory_id' IN (?)", inventory_map.keys)
        .find_each do |version|
          item = version.reify
          inventory = inventory_map[item.fleet_inventory_id]
          next if inventory.nil?

          record = inventory.fleet_inventory_items.new
          record.assign_attributes(item.attributes.slice(*INVENTORY_ITEM_COLUMNS))
          record.save!(validate: false)
        end
    end
  end
end
