# frozen_string_literal: true

module Spreadsheet
  class StarCitizenTradingLoader
    attr_accessor :base_url, :spreadsheet_id, :current_version

    def initialize
      @base_url = 'https://sheets.googleapis.com/v4/spreadsheets'
      @spreadsheet_id = '151DlYzB0A3UV4399evSid7iSkYE7l9MwAUubmBMu-Lk'
      @api_token = ENV['GOOGLE_SPREADSHEET_API_TOKEN']
      @current_version = '3.8'
    end

    def run
      sheets = fetch_sheets

      sheets.each do |sheet|
        sheet_data = fetch_sheet(sheet)
        case sheet[:name]
        when 'Commodities'
          import_commodities(sheet_data['values'])
        when 'FPS Armor'
          import_fps_armor(sheet_data['values'])
        when 'Clothing'
          import_clothing(sheet_data['values'])
        when 'FPS Weapons'
          import_fps_weapon(sheet_data['values'])
        when 'Hacking Tools'
          import_hacking_tools(sheet_data['values'])
        when 'Components'
          import_components(sheet_data['values'])
        when 'Weapons'
          import_weapons(sheet_data['values'])
        end
      end
    end

    def fetch_sheets
      response = fetch_remote("#{@base_url}/#{@spreadsheet_id}")

      return {} unless response.success?

      begin
        extract_sheets(JSON.parse(response.body))
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Spreadsheet Data could not be parsed: #{response.body}"
        {}
      end
    end

    def fetch_sheet(sheet)
      range = "#{sheet[:range][:min_column]}#{sheet[:range][:min_row]}:#{sheet[:range][:max_column]}#{sheet[:range][:max_row]}"
      range = "'#{sheet[:name]}'!#{range}"
      response = fetch_remote("#{@base_url}/#{@spreadsheet_id}/values/#{CGI.escape(range)}")

      return {} unless response.success?

      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Spreadsheet Data could not be parsed: #{response.body}"
        {}
      end
    end

    private def import_commodities(values)
      locations_data = values.shift

      save_to_file(
        'commodities',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            commodity_type: (:harvestable if row[2] == 'Harvestables'),
            prices: extract_prices(row, locations_data, 3, sell_buy_mapping[row[3]]),
          }
        end.compact
      )
    end

    private def import_fps_armor(values)
      locations_data = values.shift

      save_to_file(
        'fps_armor',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            manufacturer: row[2],
            damage_reduction: row[4].delete('%').to_f,
            storage: row[3],
            item_type: fps_type_mapping[row[5]],
            equipment_type: fps_category_mapping[row[1]],
            slot: fps_slot_mapping[row[1]],
            prices: extract_prices(row, locations_data, 6),
          }
        end.compact
      )
    end

    private def import_clothing(values)
      locations_data = values.shift

      save_to_file(
        'clothing',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            manufacturer: row[2],
            equipment_type: :clothing,
            slot: row[1].downcase.to_sym,
            prices: extract_prices(row, locations_data, 4),
          }
        end.compact
      )
    end

    private def import_hacking_tools(values)
      locations_data = values.shift

      save_to_file(
        'hacking_tools',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            equipment_type: :hacking_tool,
            prices: extract_prices(row, locations_data, 1),
          }
        end.compact
      )
    end

    private def import_fps_weapon(values)
      locations_data = values.shift

      save_to_file(
        'fps_weapons',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            equipment_type: fps_category_mapping[row[1]],
            manufacturer: row[2],
            item_type: row[3],
            weapon_class: fps_weapon_mapping[row[4]],
            extras: ("Magazine Size #{row[5]}" if row[5].present?),
            rate_of_fire: row[6],
            range: row[7],
            prices: extract_prices(row, locations_data, 12),
          }
        end.compact
      )
    end

    private def import_components(values)
      locations_data = values.shift

      save_to_file(
        'components',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            component_class: component_class_mapping[row[1]],
            manufacturer: row[2],
            size: row[3],
            grade: row[4],
            item_type: row[1],
            item_class: component_item_class_mapping[row[5]],
            prices: extract_prices(row, locations_data, 6),
          }
        end.compact
      )
    end

    private def import_weapons(values)
      locations_data = values.shift

      save_to_file(
        'weapons',
        values.map do |row|
          name = row[0]

          next if name.blank?

          {
            name: name,
            manufacturer: row[2],
            component_class: 'RSIWeapon',
            tracking_signal: tracking_signal_mapping[row[3]],
            size: row[4],
            item_type: row[1],
            prices: extract_prices(row, locations_data, 6),
          }
        end.compact
      )
    end

    private def save_to_file(name, data)
      File.open("db/seeds/99_items/#{current_version}/#{name}.json", 'w') do |f|
        f.write(data.to_json)
      end
    end

    private def extract_prices(row, locations_data, col, prefix = nil)
      price_data = row.each_with_index.select { |_val, index| index > col }.map(&:first)
      price_data.each_with_index.map do |price, index|
        next if price.blank?

        location = locations(locations_data, col)[index].split(' - ')
        {
          location: location.first,
          shop: location.last,
          "#{prefix}#{prefix ? '_' : ''}price": price,
        }
      end.compact
    end

    private def locations(data, col)
      data.each_with_index.select { |_val, index| index > col }.map(&:first)
    end

    private def tracking_signal_mapping
      {
        'IR' => 'infrared',
        'CS' => 'cross_section',
        'Elec' => 'electromagnetic',
      }
    end

    private def sell_buy_mapping
      {
        'Sell' => 'buy',
        'Buy' => 'sell',
      }
    end

    private def component_class_mapping
      {
        'quantum_drives' => 'RSIPropulsion',
        'coolers' => 'RSIModular',
        'power_plants' => 'RSIModular',
        'shield_generators' => 'RSIModular',
      }
    end

    private def component_item_class_mapping
      {
        'Industrial' => :industrial,
        'Stealth' => :stealth,
        'Civilian' => :civilian,
        'Competition' => :competition,
        'Military' => :military,
      }
    end

    private def fps_weapon_mapping
      {
        'Energy' => :energy,
        'Ballistic' => :ballistic,
        'Frag' => :frag,
      }
    end

    private def fps_type_mapping
      {
        'Flight' => :flightsuit,
        'Heavy' => :heavy_armor,
        'Medium' => :medium_armor,
        'Light' => :light_armor,
      }
    end

    private def fps_category_mapping
      {
        'Undersuit' => :undersuit,
        'Armor - Arms' => :armor,
        'Armor - Helmet' => :armor,
        'Armor - Legs' => :armor,
        'Armor - Torso' => :armor,
        'Weapons' => :weapon,
        'Attachment' => :weapon_attachment,
        'Medical Utility' => :medical,
      }
    end

    private def fps_slot_mapping
      {
        'Undersuit' => :undersuit,
        'Armor - Arms' => :arms,
        'Armor - Helmet' => :helmet,
        'Armor - Legs' => :legs,
        'Armor - Torso' => :torso,
      }
    end

    private def extract_sheets(data)
      (data['sheets'] || []).map do |sheet|
        {
          id: sheet['properties']['sheetId'],
          name: sheet['properties']['title'],
          range: {
            min_column: 'A',
            min_row: 1,
            max_column: 'ZA',
            max_row: sheet['properties']['gridProperties']['rowCount']
          }
        }
      end
    end

    private def fetch_remote(url)
      Typhoeus.get("#{url}?key=#{@api_token}")
    end
  end
end
