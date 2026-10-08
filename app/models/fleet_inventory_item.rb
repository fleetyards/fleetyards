# frozen_string_literal: true

class FleetInventoryItem < ApplicationRecord
  include InventoryLedgerEntry

  has_paper_trail on: ::VersionedItem::RECORDED_EVENTS

  paginates_per 30

  inventory_association :fleet_inventory
  position_association :fleet_inventory_position

  belongs_to :added_by_user, class_name: "User", foreign_key: :added_by, optional: true
  belongs_to :member, class_name: "User", optional: true

  after_create_commit :notify_inventory_entry, unless: :from_transfer?

  def self.ransackable_attributes(_auth_object = nil)
    %w[name category unit entry_type quality fleet_inventory_id created_at updated_at position_id fleet_inventory_position_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_inventory item]
  end

  private def notify_inventory_entry
    fleet = fleet_inventory.fleet
    recipients = fleet.fleet_memberships.kept.accepted.includes(:fleet_role, :user).select { |m|
      m.has_access?(["fleet:manage", "fleet:inventories:manage", "fleet:logistics:manage"])
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
