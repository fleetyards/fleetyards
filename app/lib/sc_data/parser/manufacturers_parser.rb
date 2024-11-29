module ScData
  module Parser
    class ManufacturersParser < ScData::Parser::BaseParser
      def run
        manufacturers = load_data("scitemmanufacturer").filter_map do |item|
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
    end
  end
end
