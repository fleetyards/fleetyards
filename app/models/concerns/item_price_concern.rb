# frozen_string_literal: true

# What a catalogue item costs lives in the one polymorphic `item_prices` table,
# whether the item is a commodity, a ship component or a piece of gear, and all
# three are asked the same things: where it can be bought, where it can be sold,
# and the cheapest of each.
module ItemPriceConcern
  extend ActiveSupport::Concern

  RANSACKABLE_ATTRIBUTES = %w[buy_price sell_price].freeze

  included do
    has_many :item_prices, as: :item, dependent: :destroy

    # Listed in each model's `ransackable_attributes` alongside its columns --
    # ransack ignores a ransacker that is not whitelisted, silently dropping the
    # condition. `type` is what makes `_gteq` compare numbers rather than the
    # strings the query string carries.
    ransacker :buy_price, type: :decimal do
      Arel.sql(cheapest_item_price_sql(:buy))
    end

    ransacker :sell_price, type: :decimal do
      Arel.sql(cheapest_item_price_sql(:sell))
    end
  end

  class_methods do
    # Joining a polymorphic has_many would repeat the item once per price row,
    # which a range filter then has to `distinct` away -- and `distinct` fights
    # the ordering ransack applies on top. A scalar subquery keeps one row per
    # item and yields exactly the number the payload exposes, so a filter
    # matches against the figure the list shows.
    def cheapest_item_price_sql(price_type)
      "(SELECT MIN(item_prices.price) FROM item_prices " \
        "WHERE item_prices.item_id = #{quoted_table_name}.id " \
        "AND item_prices.item_type = #{connection.quote(name)} " \
        "AND item_prices.price_type = #{ItemPrice.price_types.fetch(price_type.to_s)})"
    end
  end

  def sold_at
    priced(:sell).uniq { |item_price| price_location_key(item_price) }
  end

  # The best-paid quote of each terminal, best paid first: a seller flies to
  # the highest offer, and a terminal's lower quotes are ones nobody takes.
  def bought_at
    priced(:buy)
      .sort_by { |item_price| [-(item_price.price || -Float::INFINITY), *price_tie_break(item_price)] }
      .uniq { |item_price| price_location_key(item_price) }
  end

  # Cheapest first, off the loaded prices where a list preloaded them -- shop
  # links and all -- and in one query otherwise. A price nobody quoted sorts
  # last, as Postgres sorts a NULL.
  private def priced(price_type)
    rows = if item_prices.loaded?
      item_prices.select { |item_price| item_price.price_type == price_type.to_s }
    else
      item_prices.public_send(price_type).to_a
    end

    ItemPrice.with_shop_links(rows.sort_by { |item_price| [item_price.price || Float::INFINITY, *price_tie_break(item_price)] })
  end

  # sort_by is not stable: without this, two quotes of one price swap places
  # between calls, and which of a terminal's equal quotes survives is a toss.
  private def price_tie_break(item_price)
    [item_price.location.to_s, item_price.id.to_s]
  end

  # Two commodity terminals can share a name; the terminal tells them apart.
  private def price_location_key(item_price)
    item_price.terminal_id || item_price.location
  end

  def buy_price
    cheapest_price(:buy?)
  end

  def sell_price
    cheapest_price(:sell?)
  end

  # What the best-paid shop buys it back at -- the figure a seller wants, where
  # `buy_price` is the cheapest buy-back the catalogue filters on.
  def best_buy_price
    item_prices.to_a.select(&:buy?).filter_map(&:price).max
  end

  # The UEX snapshot writes prices without touching the item it prices, so a
  # payload cached on the item alone keeps serving yesterday's numbers. The
  # count catches a removed row, whose deletion moves no timestamp, and the
  # timestamp carries microseconds the way Rails' own cache keys do -- at second
  # resolution a re-priced row within the same second would go unnoticed.
  def item_prices_cache_key
    prices = item_prices.to_a
    touched_at = prices.filter_map(&:updated_at).max

    [prices.size, touched_at&.utc&.to_fs(:usec)]
  end

  # Read off the loaded association rather than through a scope, so a list that
  # preloads `item_prices` answers both price columns without a query per row.
  private def cheapest_price(price_type)
    item_prices.to_a.select(&price_type).filter_map(&:price).min
  end
end
