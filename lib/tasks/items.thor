# frozen_string_literal: true

class Items < Thor
  include Thor::Actions

  desc 'load', 'Load Items from Spreadsheet'
  def load
    require './config/environment'
    require 'spreadsheet/star_citizen_trading_loader'
    require 'dotenv'
    Dotenv.load

    ::Spreadsheet::StarCitizenTradingLoader.new.run
  end

  desc 'import', 'Import Items from json files'
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def import
    require './config/environment'

    current_version = '3.8'

    system("curl -XPUT -H \"Content-Type: application/json\" http://localhost:9200/_all/_settings -d '{\"index.blocks.read_only_allow_delete\": false}'")
    puts ''

    %w[fps_weapons clothing fps_armor commodities hacking_tools components weapons].each do |key|
      file_path = "db/seeds/99_items/#{current_version}/#{key}.json"

      next unless File.exist?(file_path)

      imported_data = JSON.parse(File.read(file_path))

      item_type = nil

      case key
      when 'fps_armor', 'clothing', 'fps_weapons', 'hacking_tools'
        item_type = 'Equipment'
      when 'components', 'weapons'
        item_type = 'Component'
      when 'commodities'
        item_type = 'Commodity'
      end

      next if item_type.blank?

      imported_data.each do |item_data|
        puts "importing #{item_type}: #{item_data['name']}"
        item = item_type.constantize.find_or_create_by(name: item_data['name']) do |_new_item|
          puts '- new item!'
        end

        prices = item_data.delete('prices') || []
        prices.each do |price|
          station = Station.find_by(name: price['location'])
          next if station.blank?

          shop = Shop.find_by(station_id: station.id, name: price['shop'])
          next if shop.blank?

          puts "adding price for #{price['shop']} on #{price['location']}"
          shop_commodity = ShopCommodity.find_or_create_by(shop_id: shop.id, commodity_item_id: item.id, commodity_item_type: item_type) do |_new_price|
            puts '- new price'
          end

          shop_commodity.update(sell_price: price['price'])
        end

        manufacturer_name = item_data.delete('manufacturer')
        if manufacturer_name.present?
          manufacturer = Manufacturer.find_or_create_by(name: manufacturer_name)
          item_data['manufacturer_id'] = manufacturer&.id
        end

        item.update(item_data)
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
end
