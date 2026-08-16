# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventory_items
#
#  id                 :uuid             not null, primary key
#  added_by           :uuid
#  category           :integer          default(0), not null
#  entry_type         :integer          default(0), not null
#  item_type          :string
#  name               :string           not null
#  notes              :text
#  quality            :integer          default(0)
#  quantity           :decimal(15, 2)   default(0.0), not null
#  unit               :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  fleet_inventory_id :uuid             not null
#  item_id            :uuid
#  member_id          :uuid
#
# Indexes
#
#  index_fleet_inventory_items_on_fleet_inventory_id  (fleet_inventory_id)
#  index_fleet_inventory_items_on_member_id           (member_id)
#
# Foreign Keys
#
#  fk_rails_...  (added_by => users.id)
#  fk_rails_...  (fleet_inventory_id => fleet_inventories.id)
#  fk_rails_...  (member_id => users.id)
#
class FleetInventoryItem < ApplicationRecord
  include InventoryLedgerEntry

  has_paper_trail

  paginates_per 30

  inventory_association :fleet_inventory

  belongs_to :added_by_user, class_name: "User", foreign_key: :added_by, optional: true
  belongs_to :member, class_name: "User", optional: true

  after_create_commit :notify_inventory_entry

  def self.ransackable_attributes(_auth_object = nil)
    %w[name category unit entry_type quality fleet_inventory_id created_at updated_at]
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
      Notification.notify!(
        user: recipient,
        type: :fleet_inventory_item_added,
        title: I18n.t("notifications.fleet_inventory_item_added.title", item_name: name, fleet: fleet.name),
        link: Rails.application.routes.url_helpers.frontend_fleet_path(fleet.slug),
        record: fleet_inventory
      )
    end
  end
end
