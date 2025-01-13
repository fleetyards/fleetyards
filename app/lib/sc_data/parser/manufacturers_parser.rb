module ScData
  module Parser
    class ManufacturersParser < ScData::Parser::BaseParser
      def all
        manufacturers = load_manufacturer_data.filter_map do |item|
          parse_manufacturer(item[:values])
        end

        save_items(manufacturers, folder: "manufacturers", key: :code)
      end

      def parse_manufacturer(values)
        code = values.dig("Code")

        return if code.blank?

        {
          code:,
          ref: value_or_nil(values.dig("__ref")),
          name: value_or_nil(translate(values.dig("Localization", "Name"))),
          short_name: value_or_nil(translate(values.dig("Localization", "ShortName"))),
          description: value_or_nil(translate(values.dig("Localization", "Description")))
        }
      end

      private def load_manufacturer_data
        Dir.glob("#{import_path}/scitemmanufacturer/*.xml").map do |file|
          data = Hash.from_xml(File.read(file))
          key = data.keys.first.split(".").last
          values = data.values.first

          {
            key:,
            values:
          }
        end +
          Dir.glob("#{import_path}/scitemmanufacturer/{armor,clothes,hangars,personalweapons,paintcolorlogos}/*.xml").map do |file|
            data = Hash.from_xml(File.read(file))
            key = data.keys.first.split(".").last
            values = data.values.first

            {
              key:,
              values:
            }
          end
      end
    end
  end
end
