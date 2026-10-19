# frozen_string_literal: true

# A paint, piece of hangar flair, FPS equipment, CCU or ship component in the
# user's RSI hangar, as read by the hangar sync. None becomes a vehicle, so all
# are kept as RSI lists them.
class HangarPledgeItem < ApplicationRecord
  paginates_per 48
  max_paginates_per 240
  per_page_steps PageSizes.up_to(max_per_page)

  KINDS = %w[paint flair equipment ccu ship_component].freeze

  # The kinds that are things to keep in an inventory.
  INVENTORY_KINDS = %w[ship_component equipment].freeze

  # The component categories the inventory ledger files as weapons: those a
  # ship's hardpoints group as weapons.
  WEAPON_CATEGORIES = %w[weapons weapon_mounts turret missile_racks bombcompartments quantumenforcementdevice].freeze

  DEFAULT_SORTING_PARAMS = [].freeze
  ALLOWED_SORTING_PARAMS = ["meltValue asc", "meltValue desc"].freeze

  belongs_to :user

  # The catalogue item a ship component or piece of gear was matched to, where
  # one was found.
  belongs_to :catalogue_component, class_name: "Component", foreign_key: :component_id, optional: true
  belongs_to :catalogue_equipment, class_name: "Equipment", foreign_key: :equipment_id, optional: true

  has_many :model_paint_links, class_name: "HangarPledgeItemModelPaint", dependent: nil
  has_many :model_paints, through: :model_paint_links

  validates :rsi_pledge_id, :name, presence: true
  validates :kind, inclusion: {in: KINDS}
  validates :quantity, numericality: {only_integer: true, greater_than: 0}

  scope :upgrades, -> { where(kind: "ccu") }
  scope :paints, -> { where(kind: "paint") }
  scope :flair, -> { where(kind: "flair") }
  scope :equipment, -> { where(kind: "equipment") }
  scope :ship_components, -> { where(kind: "ship_component") }
  scope :for_inventory, -> { where(kind: INVENTORY_KINDS) }
  scope :with_value, -> { where(pledge_value: 0.01..) }

  scope :upgrade_from_model_slug_eq, ->(slug) { upgrade_for_model(slug, 1) }
  scope :upgrade_to_model_slug_eq, ->(slug) { upgrade_for_model(slug, 2) }

  # Hangar CCUs carry ship names rather than the RSI ship ids buybacks expose.
  # Resolve the selected model at query time so already-synced CCUs work too.
  def self.upgrade_for_model(slug, position)
    model = Model.find_by(slug:)
    return none unless model

    names = [model.name, model.rsi_name].filter_map { |name| name.presence&.strip&.downcase }.uniq
    ship = <<~SQL.squish
      (regexp_match(hangar_pledge_items.name,
        '(?i)^(?:Upgrade[[:space:]]*-[[:space:]]*)?(.+?)[[:space:]]+to[[:space:]]+(.+)$'))[#{position}]
    SQL
    # RSI appends how the upgrade was sold to the target ship. Catalogue names
    # such as "Gladius Pirate Edition" end the same way, so the name is also
    # compared as it stands.
    sale = <<~SQL.squish
      regexp_replace(#{ship}, '(?i)[[:space:]]+(-[[:space:]]*)?(warbond([[:space:]]+edition)?|standard[[:space:]]+edition|best[[:space:]]+in[[:space:]]+show([[:space:]]+edition)?([[:space:]]+[0-9]{4})?)$', '')
    SQL
    # Arel instead of a bind: the regex literals contain `?` and `:name`
    # sequences that both bind styles would substitute.
    upgrades.where(Arel.sql("lower(trim(#{ship}))").in(names))
      .or(upgrades.where(Arel.sql("lower(trim(#{sale}))").in(names)))
  end

  # Newest pledge first, the order RSI lists the hangar in. Pledge ids grow
  # over time, so they order pledges created on the same day, and any pledge
  # whose date could not be read.
  def self.hangar_order
    Arel.sql(<<~SQL.squish)
      hangar_pledge_items.pledge_created_on DESC NULLS LAST,
      length(hangar_pledge_items.rsi_pledge_id) DESC,
      hangar_pledge_items.rsi_pledge_id DESC,
      hangar_pledge_items.name ASC,
      hangar_pledge_items.id ASC
    SQL
  end

  # Items without a melt value of their own go last in either direction, rather
  # than first on a descending sort as Postgres would place them.
  def self.sort_order(sorts)
    sorts.map do |sort|
      attribute, direction = sort.split
      raise ArgumentError, "unknown sort #{sort}" unless attribute == "melt_value" && %w[asc desc].include?(direction)

      Arel.sql(<<~SQL.squish)
        CASE WHEN hangar_pledge_items.pledge_item_count = hangar_pledge_items.quantity
          THEN hangar_pledge_items.pledge_value END #{direction.upcase} NULLS LAST
      SQL
    end
  end

  # Melting returns what the whole pledge is worth, so an item has a melt value
  # of its own only when it is all the pledge holds. RSI lists a poster held
  # twice as two items, which the sync stores as one row.
  def standalone?
    pledge_item_count.present? && pledge_item_count == quantity
  end

  def melt_value
    pledge_value if standalone?
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[meltable name]
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[with_value upgrade_from_model_slug_eq upgrade_to_model_slug_eq]
  end

  def self.ransackable_scopes_skip_sanitize_args
    %i[upgrade_from_model_slug_eq upgrade_to_model_slug_eq]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  # What identifies the item across syncs. A sync, or a cleared hangar synced
  # again, recreates the row but not the pledge, so a deposit remembers this
  # rather than the row, and the item is never offered for a second add.
  def source_key
    [kind, rsi_pledge_id, name].join(":")
  end

  # The user's deposits that came from these items, by source key.
  def self.deposits_for(user, items)
    keys = items.select { |item| INVENTORY_KINDS.include?(item.kind) }.map(&:source_key)
    return {} if keys.empty?

    InventoryItem.joins(:inventory)
      .where(inventories: {holder_type: user.class.name, holder_id: user.id}, source_pledge_item_key: keys)
      .includes(:inventory)
      .index_by(&:source_pledge_item_key)
  end

  # The deposit this item makes in an inventory: as many as the pledge lists,
  # referring to the catalogue item where the sync matched one.
  def inventory_entry_attributes
    catalogued = catalogue_component || catalogue_equipment

    # The catalogue's name, so the deposit joins the position of the same part
    # entered by hand; RSI's only where nothing was matched.
    {
      name: catalogued&.name.presence || name,
      category: inventory_category,
      quantity:,
      unit: "units",
      entry_type: "deposit",
      item_type: catalogued&.class&.name,
      item_id: catalogued&.id,
      source_pledge_item_key: source_key
    }
  end

  private def inventory_category
    return "equipment" if kind == "equipment"

    WEAPON_CATEGORIES.include?(catalogue_component&.category) ? "weapon" : "component"
  end
end
