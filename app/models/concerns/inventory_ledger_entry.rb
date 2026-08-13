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

  # item_type reaches us from the client, and a polymorphic belongs_to would
  # happily point an entry at any model in the app — including records the
  # signed-in user cannot see, whose name would then be copied onto the entry.
  ITEM_TYPES = %w[Component].freeze

  UNITS = {scu: 0, units: 1}.freeze

  # Only bulk cargo is measured in SCU; gear is counted per piece. "other" is
  # the escape hatch for anything that does not fit either habit.
  UNITS_BY_CATEGORY = {
    "commodity" => ["scu"],
    "component" => ["units"],
    "weapon" => ["units"],
    "equipment" => ["units"],
    "ammunition" => ["units"],
    "consumable" => ["units"],
    "other" => UNITS.keys.map(&:to_s)
  }.freeze

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
    validates :item_type, inclusion: {in: ITEM_TYPES}, allow_blank: true
    validates :item_type, presence: true, if: :item_id?
    validate :withdrawal_does_not_exceed_stock, if: :withdrawal?
    validate :referenced_item_exists, if: :item_id?
    # Existing rows predate the pairing, so only entries that touch either side
    # of it have to satisfy it.
    validate :unit_fits_category, if: -> {
      new_record? || will_save_change_to_unit? || will_save_change_to_category?
    }

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

    def units_for_category(category)
      UNITS_BY_CATEGORY.fetch(category.to_s, UNITS.keys.map(&:to_s))
    end

    def net_quantity_for(inventory_id, name, category, unit)
      where(inventory_foreign_key => inventory_id, :name => name, :category => category, :unit => unit)
        .sum("CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END")
    end
  end

  # Falls back to the referenced game item's artwork, so an entry pointing at a
  # component looks like that component without anyone uploading a picture.
  def display_image
    return image if image.attached?
    return unless referenced_item?
    return unless item.respond_to?(:store_image) && item.store_image.attached?

    item.store_image
  end

  # Reading `item` constantizes item_type, so both the name default and the
  # existence check have to wait until the type is known to be one of ours.
  def referenced_item?
    item_type.in?(ITEM_TYPES) && item.present?
  end

  private def set_name_from_item
    return if name.present?
    return unless referenced_item?

    self.name = item.name
  end

  private def referenced_item_exists
    return unless item_type.in?(ITEM_TYPES)

    errors.add(:item_id, :blank) if item.blank?
  end

  private def unit_fits_category
    return if category.blank? || unit.blank?

    allowed = self.class.units_for_category(category)
    return if unit.in?(allowed)

    errors.add(:unit, :inclusion, message: "must be #{allowed.join(" or ")} for #{category} entries")
  end

  private def withdrawal_does_not_exceed_stock
    current = self.class.net_quantity_for(inventory_id, name, category, unit)

    if quantity > current
      errors.add(:quantity, :insufficient_stock, message: "exceeds current stock (#{current})")
    end
  end
end
