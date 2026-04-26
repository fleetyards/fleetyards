# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_inventory_items
#
#  id                 :uuid             not null, primary key
#  added_by           :uuid
#  category           :integer          default("commodity"), not null
#  entry_type         :integer          default("deposit"), not null
#  item_type          :string
#  name               :string           not null
#  notes              :text
#  quality            :integer          default(0)
#  quantity           :decimal(15, 2)   default(0.0), not null
#  unit               :integer          default("scu"), not null
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
  paginates_per 30

  belongs_to :fleet_inventory, touch: true
  belongs_to :item, polymorphic: true, optional: true
  belongs_to :added_by_user, class_name: "User", foreign_key: :added_by, optional: true
  belongs_to :member, class_name: "User", optional: true

  enum :category, {
    commodity: 0,
    component: 1,
    weapon: 2,
    equipment: 3,
    ammunition: 4,
    consumable: 5,
    other: 6
  }

  enum :unit, {scu: 0, units: 1}

  enum :entry_type, {deposit: 0, withdrawal: 1}

  has_one_attached :image

  validates :quality, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1000}, allow_nil: true

  validates :name, presence: true
  validates :quantity, numericality: {greater_than: 0}
  validate :withdrawal_does_not_exceed_stock, if: :withdrawal?

  before_validation :set_name_from_item
  after_create_commit :notify_inventory_entry

  DEFAULT_SORTING_PARAMS = ["created_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "quantity asc", "quantity desc",
    "category asc", "category desc",
    "entryType asc", "entryType desc",
    "createdAt asc", "createdAt desc"
  ]

  def self.ransackable_attributes(_auth_object = nil)
    %w[name category unit entry_type quality fleet_inventory_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_inventory item]
  end

  def self.net_quantity_for(fleet_inventory_id, name, category, unit)
    where(fleet_inventory_id: fleet_inventory_id, name: name, category: category, unit: unit)
      .sum("CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END")
  end

  private def set_name_from_item
    return if item.blank?
    return if name.present?

    self.name = item.name
  end

  private def withdrawal_does_not_exceed_stock
    current = self.class.net_quantity_for(fleet_inventory_id, name, category, unit)

    if quantity > current
      errors.add(:quantity, :insufficient_stock, message: "exceeds current stock (#{current})")
    end
  end

  private def notify_inventory_entry
    fleet = fleet_inventory.fleet
    recipients = fleet.fleet_memberships.accepted.includes(:fleet_role, :user).select { |m|
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
