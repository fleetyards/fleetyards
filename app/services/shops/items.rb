# frozen_string_literal: true

module Shops
  # A shop's listing as one list, whatever catalogue each thing comes from,
  # narrowed and ordered the way the shop page asks. A shop sells a few hundred
  # things at most, so this sorts in memory rather than across four tables.
  class Items
    SORTS = ["name asc", "name desc", "price asc", "price desc"].freeze

    Row = Struct.new(:item, :prices, :category_id, :category_label) do
      # Shop-perspective, as `item_prices` stores it: what the shop sells at is
      # what a reader buys for.
      def buy_price
        prices.select(&:sell?).filter_map(&:price).min
      end

      def rental_price
        cheapest_rental&.price
      end

      # A rental is quoted for a period: 9,000 for a day is not 9,000 for a
      # week.
      def rental_time_range
        cheapest_rental&.time_range
      end

      def cheapest_rental
        prices.select { |price| price.rental? && price.price }.min_by(&:price)
      end

      def sell_price
        prices.select(&:buy?).filter_map(&:price).max
      end

      # Ordered by what a reader pays, then by what they are paid; a thing
      # with no price at all goes last either way.
      def sort_price
        buy_price || rental_price || sell_price
      end
    end

    def initialize(shop, name_cont: nil, category_in: nil, category_not_in: nil, sort: nil)
      @shop = shop
      @name_cont = name_cont.to_s.strip.downcase.presence
      @category_in = Array(category_in).map(&:to_s).compact_blank.presence
      @category_not_in = Array(category_not_in).map(&:to_s).compact_blank.presence
      @sort = SORTS.include?(sort) ? sort : SORTS.first
    end

    def call
      rows = Listing.new(@shop).call.map do |entry|
        key = Categories.key_of(entry.item)
        Row.new(entry.item, entry.prices, Categories.id_of(entry.item.class.name, key), Categories.label_of(entry.item, key))
      end

      rows = rows.select { |row| row.item.name.to_s.downcase.include?(@name_cont) } if @name_cont
      rows = rows.select { |row| @category_in.include?(row.category_id) } if @category_in
      rows = rows.reject { |row| @category_not_in.include?(row.category_id) } if @category_not_in

      sorted(rows)
    end

    # For the page being shown, not every match.
    def self.preload_manufacturers(rows)
      rows.map(&:item).select { |item| item.class.reflect_on_association(:manufacturer) }.group_by(&:class).each_value do |items|
        ActiveRecord::Associations::Preloader.new(records: items, associations: :manufacturer).call
      end
    end

    private def sorted(rows)
      field, direction = @sort.split
      by_name = ->(row) { row.item.name.to_s.downcase }

      if field == "price"
        priced, unpriced = rows.partition(&:sort_price)
        priced = priced.sort_by { |row| [row.sort_price, by_name.call(row)] }
        priced.reverse! if direction == "desc"
        priced + unpriced.sort_by(&by_name)
      else
        rows = rows.sort_by(&by_name)
        (direction == "desc") ? rows.reverse : rows
      end
    end
  end
end
