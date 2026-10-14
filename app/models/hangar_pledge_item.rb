# frozen_string_literal: true

# A paint, piece of hangar flair, FPS equipment or CCU in the user's RSI hangar,
# as read by the hangar sync. None becomes a vehicle, so all are kept as RSI
# lists them.
class HangarPledgeItem < ApplicationRecord
  paginates_per 48
  max_paginates_per 240
  per_page_steps PageSizes.up_to(max_per_page)

  KINDS = %w[paint flair equipment ccu].freeze

  belongs_to :user

  has_many :model_paint_links, class_name: "HangarPledgeItemModelPaint", dependent: nil
  has_many :model_paints, through: :model_paint_links

  validates :rsi_pledge_id, :name, presence: true
  validates :kind, inclusion: {in: KINDS}
  validates :quantity, numericality: {only_integer: true, greater_than: 0}

  scope :upgrades, -> { where(kind: "ccu") }
  scope :paints, -> { where(kind: "paint") }
  scope :flair, -> { where(kind: "flair") }
  scope :equipment, -> { where(kind: "equipment") }
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
    # Arel instead of a bind: the regex literals contain `?` and `:name`
    # sequences that both bind styles would substitute.
    upgrades.where(Arel.sql(<<~SQL.squish).in(names))
      lower(trim(regexp_replace(#{ship}, '(?i)[[:space:]]+(-[[:space:]]*)?warbond([[:space:]]+edition)?$', '')))
    SQL
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
end
