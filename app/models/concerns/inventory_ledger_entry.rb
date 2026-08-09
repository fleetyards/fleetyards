# frozen_string_literal: true

module InventoryLedgerEntry
  extend ActiveSupport::Concern

  CATEGORIES = {
    commodity: 0,
    component: 1,
    weapon: 2,
    equipment: 3,
    ammunition: 4,
    consumable: 5,
    other: 6
  }.freeze

  UNITS = {scu: 0, units: 1}.freeze

  ENTRY_TYPES = {deposit: 0, withdrawal: 1}.freeze

  DEFAULT_SORTING_PARAMS = ["created_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "quantity asc", "quantity desc",
    "category asc", "category desc",
    "entryType asc", "entryType desc",
    "createdAt asc", "createdAt desc"
  ]

  included do
    belongs_to :item, polymorphic: true, optional: true

    has_one_attached :image

    enum :category, CATEGORIES
    enum :unit, UNITS
    enum :entry_type, ENTRY_TYPES

    validates :name, presence: true
    validates :quantity, numericality: {greater_than: 0}
    validates :quality, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1000}, allow_nil: true
    validate :withdrawal_does_not_exceed_stock, if: :withdrawal?

    before_validation :set_name_from_item
  end

  class_methods do
    def inventory_association(association_name)
      belongs_to association_name, touch: true

      alias_method :inventory, association_name
      alias_attribute :inventory_id, :"#{association_name}_id"

      @inventory_foreign_key = :"#{association_name}_id"
    end

    def inventory_foreign_key
      @inventory_foreign_key
    end

    def net_quantity_for(inventory_id, name, category, unit)
      where(inventory_foreign_key => inventory_id, :name => name, :category => category, :unit => unit)
        .sum("CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END")
    end
  end

  private def set_name_from_item
    return if item.blank?
    return if name.present?

    self.name = item.name
  end

  private def withdrawal_does_not_exceed_stock
    current = self.class.net_quantity_for(inventory_id, name, category, unit)

    if quantity > current
      errors.add(:quantity, :insufficient_stock, message: "exceeds current stock (#{current})")
    end
  end
end
