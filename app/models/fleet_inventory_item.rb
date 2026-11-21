# frozen_string_literal: true

class FleetInventoryItem < ApplicationRecord
  include InventoryLedgerEntry

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 24

  inventory_association :fleet_inventory
  position_association :fleet_inventory_position

  belongs_to :added_by_user, class_name: "User", foreign_key: :added_by, optional: true
  belongs_to :member, class_name: "User", optional: true

  # Which member is carrying this share of the stock in game. Blank is the
  # unassigned share. A withdrawal comes out of its holder's share, so the
  # holders of a position always add up to its total.
  belongs_to :holder, class_name: "User", optional: true

  # A deposit only: a withdrawal names whoever the stock is coming from, and
  # that may well be someone who has since left the fleet and is handing it
  # back. Checked on change, so an entry naming a former member stays editable.
  validate :holder_belongs_to_fleet, if: -> { deposit? && holder_id.present? && will_save_change_to_holder_id? }

  # Set on the two entries a hand-over writes. Nothing arrives that the
  # managers need telling about: the stock only changed hands.
  attr_accessor :handover

  after_create_commit :notify_inventory_entry, unless: -> { from_transfer? || handover }

  # How much of this entry's lot the given holder carries; nil is the
  # unassigned share.
  def lot_held_by(holder_id)
    lot_entries.where(holder_id:).sum("CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name category unit entry_type quality fleet_inventory_id created_at updated_at position_id fleet_inventory_position_id holder_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_inventory item]
  end

  private def balance_conditions
    {holder_id:}
  end

  # A holder's share is split by grade like the stock is, so a withdrawal at
  # a grade its holder does not carry would leave a negative lot the stock
  # list hides, and the holders of a row would stop adding up to its total.
  private def lots_held_apart?
    true
  end

  private def lot_shortfall_message(current)
    return "exceeds the unassigned stock at this grade (#{current})" if holder.nil?

    "exceeds what #{holder.username} holds at this grade (#{current})"
  end

  private def stock_shortfall_message(current)
    return "exceeds the unassigned stock (#{current})" if holder.nil?

    "exceeds what #{holder.username} holds (#{current})"
  end

  # A transfer returning goods puts them back with whoever sent them, member
  # or not -- the fleet is only undoing its own withdrawal.
  private def holder_belongs_to_fleet
    return if from_transfer?
    return if fleet_inventory&.fleet&.fleet_memberships&.kept&.exists?(user_id: holder_id, aasm_state: "accepted")

    errors.add(:holder_id, :not_a_member)
  end

  private def notify_inventory_entry
    fleet = fleet_inventory.fleet
    recipients = fleet.fleet_memberships.kept.accepted.includes(:fleet_role, :user).select { |m|
      m.has_access?(["fleet:manage", "fleet:inventories:manage"])
    }.filter_map { |m| m.user if m.user.email.present? }

    # Also notify the inventory manager if set
    if fleet_inventory.manager.present? && !recipients.include?(fleet_inventory.manager)
      recipients << fleet_inventory.manager
    end

    recipients.each do |recipient|
      I18n.with_locale(recipient.notification_locale) do
        Notification.notify!(
          user: recipient,
          type: :fleet_inventory_item_added,
          title: I18n.t("notifications.fleet_inventory_item_added.title", item_name: name, fleet: fleet.name),
          link: "/fleets/#{fleet.slug}/logistics/inventories/#{fleet_inventory.slug}",
          record: fleet_inventory
        )
      end
    end
  end
end
