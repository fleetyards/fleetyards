module ScData
  module Loader
    class BaseLoader
      attr_accessor :sc_version, :sc_environment

      def self.all(sc_environment: nil, sc_version: nil)
        sc_version ||= Rails.configuration.app.sc_data[:version]
        sc_environment ||= Rails.configuration.app.sc_data[:environment]

        ::ScData::Loader::ManufacturersLoader.new(sc_environment:, sc_version:).all
        ::ScData::Loader::ItemsLoader.new(sc_environment:, sc_version:).all
        ::ScData::Loader::ModelsLoader.new(sc_environment:, sc_version:).all
        ::ScData::Loader::ModelModulesLoader.new(sc_environment:, sc_version:).all
      end

      def initialize(sc_environment: nil, sc_version: nil)
        self.sc_environment = sc_environment || Rails.configuration.app.sc_data[:environment]
        self.sc_version = sc_version || Rails.configuration.app.sc_data[:version]
      end

      def load_item(path)
        JSON.parse(Rails.root.join("data/sc_data/parsed/#{sc_environment}/#{path}.json").read)
      end

      def find_item_by_ref(path, ref)
        load_items(path).find { |item| item[:ref] == ref }
      end

      def find_item_by_key(path, key)
        load_items(path).find { |item| item[:key] == key }
      end

      def load_items(path)
        Dir.glob(Rails.root.join("data/sc_data/parsed/#{sc_environment}/#{path}/**/*.json")).map do |file|
          JSON.parse(File.read(file)).with_indifferent_access
        end
      end

      def lookup_manufacturer(ref)
        Manufacturer.find_by(sc_ref: ref)
      end

      def update_cargo_holds(hardpoints, update_params)
        cargo_holds = extract_type_data(hardpoints, "CargoGrid")

        return update_params if cargo_holds.blank?

        update_params[:cargo_holds] = cargo_holds

        update_params
      end

      def extract_type_data(hardpoints, component_type)
        hardpoints.filter_map do |hardpoint|
          if hardpoint.hardpoints.present?
            extract_type_data(hardpoint.hardpoints, component_type)
          else
            next if hardpoint.component.blank?
            next if hardpoint.component.component_type != component_type

            hardpoint.component.type_data
          end
        end.flatten
      end

      private def update_loadout(parent, loadout, cleanup: true)
        hardpoint_ids = []

        (loadout["loadout"] || loadout["default_loadout"]).each do |item|
          default_loadout = loadout["default_loadout"]&.find { |dl| dl["name"] == item["name"] }

          next if loadout_name_blacklisted?(item["name"], default_loadout)

          hardpoint = parent.hardpoints.find_or_initialize_by(sc_name: item["name"].downcase)

          if item["key"].blank? && default_loadout.present?
            item["key"] = default_loadout["key"]
            item["ref"] = default_loadout["ref"]
            item["default_loadout"] = default_loadout["default_loadout"] if default_loadout["default_loadout"].present?
          end

          component = if item["key"].present?
            Component.find_by(sc_key: item["key"]&.downcase, version: sc_version)
          elsif item["ref"].present?
            Component.find_by(sc_ref: item["ref"], version: sc_version)
          end

          if component.present?
            if component.hidden?
              hardpoint_data = {
                "loadout" => component.hardpoints.filter_map do |hp|
                               next if hp.component.blank?
                               next if loadout_name_blacklisted?(hp.component.sc_key)

                               {
                                 "name" => "#{item["name"]}-#{hp.sc_name}",
                                 "key" => hp.component.sc_key
                               }
                             end
              }

              hardpoint_ids += update_loadout(parent, hardpoint_data, cleanup: false) if hardpoint_data["loadout"].present?
            else
              hardpoint.update!(
                source: :game_files,
                component: component,
                min_size: component.size,
                max_size: component.size
              )

              hardpoint_ids << hardpoint.id
            end
          else
            hardpoint.update!(
              source: :game_files,
              component: nil
            )
          end

          p item
          if item["loadout"].present? || item["default_loadout"].present?
            p item
            update_loadout(hardpoint, item) if hardpoint.persisted?
          end

          hardpoint_ids << hardpoint.id if hardpoint.persisted?
        end

        parent.hardpoints.where(source: :game_files).where.not(id: hardpoint_ids).destroy_all if cleanup

        hardpoint_ids
      end

      private def loadout_name_blacklisted?(name, default_loadout = nil)
        blacklist = [
          "aegs_retaliator_door_cap_rear", "aegs_retaliator_door_cap_front", # Retaliator door caps
          "rsi_constellation_ph_baywall_right", "rsi_constellation_ph_baywall_left", # Constellation Pheonix bay walls
          "rsi_constellation_base_baywall_right", "rsi_constellation_base_baywall_left" # Constellation Base bay walls
        ]

        if default_loadout.present?
          return blacklist.include?(default_loadout["key"]&.downcase) || blacklist.include?(default_loadout["ref"])
        end

        blacklist.include?(name&.downcase)
      end
    end
  end
end
