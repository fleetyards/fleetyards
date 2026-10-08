class ItemPrice < ApplicationRecord
  belongs_to :item, polymorphic: true
  belongs_to :terminal, optional: true
  # The shop `location` names, matched from that string by
  # Uex::ShopLocationMatcher.
  belongs_to :shop, optional: true

  # What a price's shop link reads: the shop, its place, and the parent that
  # tells two places of one name apart.
  SHOP_LINK = {shop: {location: :parent}}.freeze

  # For a fragment that embeds the prices of items it cannot list up front --
  # a ship's loadout nests components a few slots deep. The count catches a
  # deleted row, as in ItemPriceConcern#item_prices_cache_key; the query cache
  # answers every fragment of a request after the first.
  def self.cache_key_for(*item_types)
    count, touched_at = where(item_type: item_types).pick(Arel.sql("COUNT(*)"), Arel.sql("MAX(updated_at)"))

    [*item_types, count, touched_at&.utc&.to_fs(:usec)]
  end

  def self.with_shop_links(prices)
    ActiveRecord::Associations::Preloader.new(records: prices, associations: SHOP_LINK).call
    prices
  end

  enum :price_type,
    {buy: 0, sell: 1, rental: 2},
    validate: true

  enum :time_range,
    {"1-day": 0, "3-days": 1, "7-days": 2, "30-days": 3},
    validate: {allow_nil: true}

  validates :time_range, presence: true, if: -> { rental? }
  validates :price, presence: true
  validates :location, presence: true
  # Rendered as an `href`, and admin-writable, so a `javascript:` value here
  # would run on click. The views check the scheme too, for rows that predate
  # this.
  validates :location_url, format: {with: %r{\Ahttps?://}i}, allow_blank: true

  def self.ransackable_attributes(auth_object = nil)
    [
      "item_id", "item_type", "location"
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    ["item"]
  end
end
