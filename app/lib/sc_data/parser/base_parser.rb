module ScData
  module Parser
    class BaseParser
      attr_accessor :base_path, :export_path, :import_path, :definition_path, :translations

      FOUNDRY_PATH = "Data/Libs/Foundry/Records"

      SCU_DIMENSIONS = 1.25

      CARGO_CONTAINER_DIMENSIONS = [
        {
          size: 32,
          dimensions: {
            x: 8 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 24,
          dimensions: {
            x: 6 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 16,
          dimensions: {
            x: 4 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 8,
          dimensions: {
            x: 2 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 2 * SCU_DIMENSIONS
          }
        },
        {
          size: 4,
          dimensions: {
            x: 2 * SCU_DIMENSIONS,
            y: 2 * SCU_DIMENSIONS,
            z: 1 * SCU_DIMENSIONS
          }
        },
        {
          size: 2,
          dimensions: {
            x: 2 * SCU_DIMENSIONS,
            y: 1 * SCU_DIMENSIONS,
            z: 1 * SCU_DIMENSIONS
          }
        },
        {
          size: 1,
          dimensions: {
            x: 1 * SCU_DIMENSIONS,
            y: 1 * SCU_DIMENSIONS,
            z: 1 * SCU_DIMENSIONS
          }
        }
      ]

      def self.all(base_folder:, sc_version:, sc_environment:)
        ::ScData::Parser::ItemsParser.new(base_folder:, sc_version:, sc_environment:).all
        ::ScData::Parser::ManufacturersParser.new(base_folder:, sc_version:, sc_environment:).all
        ::ScData::Parser::ModelsParser.new(base_folder:, sc_version:, sc_environment:).all
      end

      def initialize(base_folder:, sc_version:, sc_environment:)
        self.base_path = "#{base_folder}/raw/#{sc_version}"
        self.export_path = "#{base_folder}/parsed/#{sc_environment}"
        self.import_path = "#{base_path}/#{FOUNDRY_PATH}"
        self.definition_path = "#{base_path}/Data"
        self.translations = parse_translations

        FileUtils.mkdir_p(export_path) unless File.directory?(export_path)
      end

      private def load_data(path)
        Dir.glob("#{import_path}/#{path}/**/*.xml").map do |file|
          data = Hash.from_xml(File.read(file))
          key = data.keys.first.split(".").last
          values = data.values.first

          {
            key:,
            values:
          }
        end
      end

      private def load_scripts_data(path)
        data = Hash.from_xml(File.read("#{definition_path}/#{path}"))
        key = data.keys.first.split(".").last
        values = data.values.first

        {
          key:,
          values:
        }
      rescue Errno::ENOENT => _e
        nil
      end

      private def save_items(items, folder:, key: :key, prefix: nil)
        return if items.blank?

        items_path = "#{export_path}/#{folder}"

        FileUtils.mkdir_p(items_path) unless File.directory?(items_path)

        items.each do |item|
          file_name = [prefix, item[key].downcase].compact.join("_")

          p "Duplicate key: #{file_name}" if File.exist?("#{items_path}/#{file_name}.json")

          File.write("#{items_path}/#{file_name}.json", JSON.pretty_generate(item))
        end
      end

      private def parse_translations
        load_ini_file("#{base_path}/Data/Localization/english/global.ini")
      end

      private def blacklisted_item_key?(key)
        [
          "camera", "panel", "animated", "light", "decal", "sensor", "button",
          "handle", "dashboard", "seataccess", "screen", "hud", "helper", "oc", "escape", "esc",
          "barrel", "firingmechanism", "powerarray", "ventilation", "interior", "mfd"
        ].any? do |filter|
          key.downcase.split("_").any? { |part| part == filter }
        end
      end

      private def translate(key)
        return nil if key.blank?
        return nil if key == "@LOC_EMPTY"

        return translations.dig(key.delete("@")) if key.starts_with?("@")

        key
      end

      private def load_ini_file(path)
        data = {}

        File.readlines(path, encoding: "UTF-8").each do |line|
          line = line.chomp

          unless /^\#/.match?(line)
            if /^([^=]+?)\s*=\s*(.*?)\s*$/.match?(line)
              param, val = line.split(/\s*=\s*/, 2)

              var_name = param.to_s.chomp.strip
              val = val.chomp.strip

              data[var_name] = val
            end
          end
        end

        data
      end

      private def value_or_nil(value)
        if value == "<= PLACEHOLDER =>" ||
            value == "UNDEFINED" ||
            value == "00000000-0000-0000-0000-000000000000" ||
            value.blank?
          return nil
        end

        value
      end
    end
  end
end
