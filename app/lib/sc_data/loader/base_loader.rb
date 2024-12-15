module ScData
  module Loader
    class BaseLoader
      attr_accessor :sc_version

      def self.run_all(sc_version: nil)
        sc_version ||= Rails.configuration.app.sc_data_sc_version

        ::ScData::Loader::ManufacturersLoader.new(sc_version:).run
        ::ScData::Loader::ItemsLoader.new(sc_version:).run
        ::ScData::Loader::ModelsLoader.new(sc_version:).run
        ::ScData::Loader::ModelModulesLoader.new(sc_version:).run
      end

      def initialize(sc_verison: nil)
        self.sc_version = sc_version || Rails.configuration.app.sc_data_sc_version
      end

      def load_item(path)
        JSON.parse(Rails.root.join("data/sc_data/parsed/#{sc_version}/#{path}.json").read)
      end

      def find_item_by_ref(path, ref)
        load_items(path).find { |item| item[:ref] == ref }
      end

      def find_item_by_key(path, key)
        load_items(path).find { |item| item[:key] == key }
      end

      def load_items(path)
        Dir.glob(Rails.root.join("data/sc_data/parsed/#{sc_version}/#{path}/**/*.json")).map do |file|
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

      private def update_loadout(parent, loadout, default_loadout = nil, cleanup: true)
        hardpoint_ids = []

        loadout.each do |item|
          hardpoint = parent.hardpoints.find_or_initialize_by(sc_name: item["name"].downcase)

          if item["key"].blank? && default_loadout.present?
            dl = default_loadout.find { |dl| dl["name"] == item["name"] }
            item["key"] = dl["key"] if dl.present?
            item["ref"] = dl["ref"] if dl.present?
          end

          component = if item["key"].present?
            Component.find_by(sc_key: item["key"]&.downcase)
          elsif item["ref"].present?
            Component.find_by(sc_ref: item["ref"])
          end

          if component.present?
            if component.hidden?
              hardpoint_data = component.hardpoints.filter_map do |hp|
                next if hp.component.blank?

                {
                  "name" => "#{item["name"]}-#{hp.sc_name}",
                  "key" => hp.component.sc_key
                }
              end

              hardpoint_ids += update_loadout(parent, hardpoint_data, nil, cleanup: false) if hardpoint_data.present?
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

          if item["loadout"].present?
            update_loadout(hardpoint, item["loadout"]) if hardpoint.persisted?
          end

          hardpoint_ids << hardpoint.id if hardpoint.persisted?
        end

        parent.hardpoints.where(source: :game_files).where.not(id: hardpoint_ids).destroy_all if cleanup

        hardpoint_ids
      end
    end
  end
end
