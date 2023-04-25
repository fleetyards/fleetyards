# frozen_string_literal: true

module ScData
  class StarmapLoader < ::ScData::BaseLoader
    CATEGORIES_FOR_IMPORT = %w[Outpost Planet Station].freeze

    STATION_TYPES = %i[station outpost].freeze

    def run
      starmap_data = load_starmap_data

      items = extract_stations(starmap_data)

      items.each do |item|
        if STATION_TYPES.include?(item[:type])

          Station.create!(
            name: item[:name],
            description: item[:description],
            station_type: item[:type]
          )
        else
          CelestialObject.create!(
            name: item[:name],
            description: item[:description]
          )
        end
      end
    end

    private def load_starmap_data
      load_from_export("starmap.json")
    end

    private def extract_stations(starmap_data)
      starmap_data.filter_map do |data_item|
        next if data_item["hideInStarmap"] == "1"
        next unless CATEGORIES_FOR_IMPORT.include?(data_item["navIcon"])

        case data_item["navIcon"]
        when "Station", "Outpost"
          station = find_station(data_item)

          next if station.blank?

          station
        when "Planet"
          celestial_object = find_celestial_object(data_item)

          next if celestial_object.blank?

          celestial_object
        end
      end
    end

    private def find_station(data_item)
      name, name_without_dash = normalize_name(data_item["name"])

      return if name.blank?

      station = Station.find_by("name LIKE ?", "%#{name}%")
      station = Station.find_by("name LIKE ?", "%#{name_without_dash}%") if station.blank?

      return if station.present?

      {
        type: ((data_item["navIcon"] == "Station") ? :station : :outpost),
        name: data_item["name"],
        description: data_item["description"]
      }
    end

    private def find_celestial_object(data_item)
      name, name_without_dash = normalize_name(data_item["name"])

      return if name.blank?

      celestial_object = CelestialObject.find_by("name LIKE ?", "%#{name}%")
      if celestial_object.blank?
        celestial_object = Station.find_by(
          "name LIKE ?", "%#{name_without_dash}%"
        )
      end

      return if celestial_object.present?

      {
        type: :celestial_object,
        name: data_item["name"],
        description: data_item["description"]
      }
    end

    private def normalize_name(data_name)
      return if excluded_from_import?(data_name)

      normalized_name = (data_name || "").delete('"')
        .delete("\t\r\n")
        .squish

      [normalized_name, normalized_name.tr("-", " ")]
    end

    private def excluded_from_import?(name)
      mapping = [
        "Cry-Astro Service 042", # CryAstro no longer exists,
        "WIP Refinery_0001" # No WIP Imports
      ]

      return true if mapping.include?(name)

      false
    end
  end
end
