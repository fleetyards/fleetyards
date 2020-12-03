# frozen_string_literal: true

module TradingData
  class Importer
    attr_accessor :json_file_path

    def initialize
      self.json_file_path = 'public/trading_data.json'
    end

    def run
      price_count_before = CommodityPrice.count
      shop_commodity_count_before = ShopCommodity.count

      data = load_data

      data.each do |item|
        shop = Shop.find_by!(slug: item['shop'])
        commodity = Commodity.find_by!(name: item['commodity'])

        shop_commodity = ShopCommodity.find_or_create_by(
          commodity_item_type: 'Commodity',
          commodity_item_id: commodity.id,
          shop_id: shop.id,
          confirmed: true
        )

        CommodityPrice.find_or_create_by(
          shop_commodity_id: shop_commodity.id,
          price: item['price'],
          type: (item['buy'] ? 'CommodityBuyPrice' : 'CommoditySellPrice'),
          confirmed: true
        )
      end

      {
        new_prices_created: CommodityPrice.count - price_count_before,
        new_shop_commodities_created: ShopCommodity.count - shop_commodity_count_before,
        items: data.size
      }
    end

    private def load_data
      file = (File.read(json_file_path) if File.exist?(json_file_path))

      JSON.parse(file)
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error 'Trading Data could not be parsed!'
      []
    end
  end
end
