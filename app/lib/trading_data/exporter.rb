# frozen_string_literal: true

module TradingData
  class Exporter
    attr_accessor :base_url, :json_file_path

    def initialize
      self.base_url = 'https://sc-trading.kamille.ovh/price'

      self.json_file_path = 'public/trading_data.json'
    end

    def run
      response = fetch_remote('/')

      page = Nokogiri::HTML(response.body)

      locations = extract_locations(page)

      data = map_data(extract_data(page), locations)

      File.write(json_file_path, data.to_json)

      data
    end

    private def extract_data(page)
      data = []

      page.css('table tbody tr').each_with_index do |row, row_index|
        next if row_index.zero? # skip first row

        commodity = nil
        row.css('td').each_with_index do |col, col_index|
          if col_index.zero?
            commodity = col.text
            next
          end

          item = col.css('button:not(.hide)').first

          next if item.blank?

          data << {
            commodity: commodity,
            price: item.text,
            location: item['data-location_id'],
            buy: item['data-buy'] == '0'
          }
        end
      end

      data
    end

    private def extract_locations(page)
      page.css('table thead tr th').map do |head|
        next if head['id'].blank?

        {
          id: head['id'],
          name: head.text
        }
      end
    end

    private def map_data(data, locations)
      data.map do |item|
        location = locations.find { |loc| loc[:id] == item[:location] }

        return item if location.blank?

        station = Station.where('name ILIKE ?', station_mapping[location[:name]] || location[:name]).first!

        shop = (station.shops.where(name: shop_mapping[location[:name]] || 'Admin Office').first! if station.present?)

        Commodity.find_by!(name: item[:commodity])

        item.merge(location: location[:name], station: station.slug, shop: shop.slug)
      end
    end

    private def fetch_remote(path)
      Typhoeus.get("#{base_url}/#{path}")
    end

    private def station_mapping
      {
        'ArcCorp Mining 141' => 'ArcCorp Mining Area 141',
        'ArcCorp Mining 157' => 'ArcCorp Mining Area 157',
        'Area18 - TDD' => 'Area 18',
        'Area18 - IO North Tower' => 'Area 18',
        'Deakins Research' => 'Deakins Research Outpost',
        'Hickes Research' => 'Hickes Research Outpost',
        'Jumptown' => 'Jump Town',
        'Lorville - CBD' => 'Lorville',
        'Lorville - L19 Admin Office' => 'Lorville',
        'New Babbage TDD' => 'New Babbage',
        'New Babbage MT Planetary Services' => 'New Babbage',
        'Reclamation & Disposal Orinth' => 'Reclamation and Disposal Orinth',
        'R&R ARC-L1' => 'ARC-L1 Wide Forest Station',
        'R&R CRU-L1' => 'CRU-L1 Ambitious Dream Station',
        'R&R CRU-L4' => 'CRU-L4 Shallow Fields Stations',
        'R&R CRU-L5' => 'CRU-L5 Beautiful Glen Station',
        'R&R HUR-L1' => 'HUR-L1 Green Glade Station',
        'R&R HUR-L2' => 'HUR-L2 Faithful Dream Station',
        'R&R HUR-L3' => 'HUR-L3 Thundering Express Station',
        'R&R HUR-L4' => 'HUR-L4 Melodic Fields Station',
        'R&R HUR-L5' => 'HUR-L5 High Course Station',
        'R&R MIC-L1' => 'MIC-L1 Shallow Frontier Station'
      }
    end

    private def shop_mapping
      {
        'Area18 - TDD' => 'Trade & Development Division',
        'Area18 - IO North Tower' => 'ArcCorp Tower',
        'Lorville - CBD' => 'CBD Transfers',
        'New Babbage TDD' => 'Trade & Development Division',
        'New Babbage MT Planetary Services' => 'Planetary Services'
      }
    end
  end
end
