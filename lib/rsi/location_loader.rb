# frozen_string_literal: true

require 'rsi/base_loader'

module RSI
  class LocationLoader < ::RSI::BaseLoader
    attr_accessor :locations

    def initialize(options = {})
      super

      @locations = options[:locations] || %w[Stanton Nyx Pyro]
    end

    def all
      starsystems = load_starsysyems

      starsystems.select do |starsystem|
        locations.include?(starsystem['name'])
      end.each do |data|
        starsystem = sync_starsystem(data)

        objects = load_celestial_objects(starsystem.code)

        objects.select do |object|
          %w[PLANET SATELLITE ASTEROID_BELT ASTEROID_FIELD].include?(object['type'])
        end.each do |object|
          sync_celestial_object(object, starsystem.id)
        end

        objects.select do |object|
          %w[MANMADE].include?(object['type'])
        end.each do |object|
          update_stations(object)
        end
      end
    end

    def load_starsysyems
      json_file_path = 'public/starsystems.json'
      return JSON.parse(File.read(json_file_path))['data']['resultset'] if Rails.env.test? && File.exist?(json_file_path)

      response = Typhoeus.post("#{base_url}/api/starmap/star-systems")

      return [] unless response.success?

      begin
        starsystems_data = JSON.parse(response.body)
        File.open(json_file_path, 'w') do |f|
          f.write(starsystems_data.to_json)
        end
        starsystems_data['data']['resultset']
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Starsysyems Data could not be parsed: #{response.body}"
        []
      end
    end

    def sync_starsystem(data)
      starsystem = create_or_update_starsystem(data)

      create_or_update_affiliations(starsystem, data['affiliation'])

      starsystem.save!

      starsystem
    end

    def load_celestial_objects(starsystem_code)
      json_file_path = "public/celestial_objects_#{starsystem_code}.json"
      if Rails.env.test? && File.exist?(json_file_path)
        starsystem = starsystem_data['data']['resultset'].first
        if starsystem.present?
          starsystem['celestial_objects']
        else
          []
        end
      end

      response = Typhoeus.post("#{base_url}/api/starmap/star-systems/#{starsystem_code}")

      return [] unless response.success?

      begin
        starsystem_data = JSON.parse(response.body)
        File.open(json_file_path, 'w') do |f|
          f.write(starsystem_data.to_json)
        end
        starsystem = starsystem_data['data']['resultset'].first
        if starsystem.present?
          starsystem['celestial_objects']
        else
          []
        end
      rescue JSON::ParserError => e
        Raven.capture_exception(e)
        Rails.logger.error "Starsysyem Data could not be parsed: #{response.body}"
        []
      end
    end

    def sync_celestial_object(data, starsystem_id)
      celestial_object = create_or_update_celestial_object(data, starsystem_id)

      create_or_update_affiliations(celestial_object, data['affiliation'])

      celestial_object.save!

      celestial_object
    end

    private def create_or_update_starsystem(data)
      starsystem = Starsystem.find_or_create_by!(rsi_id: data['id'])

      starsystem.update!(
        name: data['name'],
        code: data['code'],
        position_x: data['position_x'],
        position_y: data['position_y'],
        position_z: data['position_z'],
        description: data['description'],
        status: data['status'],
        last_updated_at: data['time_modified'],
        system_type: data['type'],
        aggregated_size: data['aggregated_size'],
        aggregated_population: data['aggregated_population'],
        aggregated_economy: data['aggregated_economy'],
        aggregated_danger: data['aggregated_danger']
      )

      starsystem
    end

    private def create_or_update_affiliations(affiliationable, data = [])
      affiliationable.affiliations.destroy_all

      data.each do |faction_data|
        faction = Faction.find_or_create_by!(rsi_id: faction_data['id'])
        faction.update(
          name: faction_data['name'],
          code: faction_data['code'],
          color: faction_data['color']
        )
        Affiliation.create(affiliationable: affiliationable, faction_id: faction.id)
      end
    end

    private def create_or_update_celestial_object(data, starsystem_id)
      celestial_object = CelestialObject.find_or_create_by!(rsi_id: data['id'])

      celestial_object.update!(
        starsystem_id: starsystem_id,
        parent: CelestialObject.find_by(rsi_id: data['parent_id']),
        name: data['name'] || data['designation'],
        designation: data['designation'],
        description: data['description'],
        object_type: data['type'],
        code: data['code'],
        status: data['status'],
        last_updated_at: data['time_modified'],
        orbit_period: data['orbit_period'],
        habitable: data['habitable'],
        fairchanceact: data['fairchanceact'],
        sensor_population: data['sensor_population'],
        sensor_economy: data['sensor_economy'],
        sensor_danger: data['sensor_danger'],
        size: data['size'],
        sub_type: (data['subtype']['name'] if data['subtype'].present?)
      )

      celestial_object
    end

    private def update_stations(data)
      station = Station.find_by(name: data['name'] || data['designation'])

      return if station.blank?

      station.update!(description: data['description'])

      station
    end
  end
end
