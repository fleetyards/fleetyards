module ScData
  module Parser
    class ManufacturersParser < ScData::Parser::BaseParser
      OVERRIDES_PATH = "config/sc_data/manufacturer_overrides.yml"

      def all
        manufacturers = load_manufacturer_data.filter_map do |item|
          parse_manufacturer(item[:values])
        end

        manufacturers.each { |manufacturer| save_icon(manufacturer[:icon]) }

        save_items(manufacturers, folder: "manufacturers", key: :code)
      end

      def parse_manufacturer(values)
        code = values.dig("Code")

        return if code.blank?

        override = overrides[code].to_h

        return if override["skip"]

        name, description = localization(values, code, override)

        {
          code:,
          ref: value_or_nil(values.dig("__ref")),
          name: value_or_nil(name),
          short_name: value_or_nil(translate(values.dig("Localization", "ShortName"))),
          description: value_or_nil(description),
          # Downcased to match the icon paths equipment and commodities record,
          # since whatever resolves one of them has to resolve all three.
          icon: value_or_nil(values.dig("Logo"))&.downcase
        }
      end

      def overrides
        @overrides ||= begin
          path = Rails.root.join(OVERRIDES_PATH)

          path.exist? ? (YAML.safe_load_file(path) || {}) : {}
        end
      end

      # The record's own `manufacturer_Name<CODE>` key wins over the key its
      # Localization block names. Several records carry a copy-pasted block
      # pointing at another manufacturer -- mxox.xml asks for
      # `@manufacturer_NameAEGS` even though `manufacturer_NameMXOX` ("maxOx")
      # is right there -- and following the block verbatim is what mints a
      # duplicate "Aegis Dynamics". Records whose code and key merely spell the
      # same company differently (GAM/GAMA, MIT/MITE) have no own key, so they
      # keep falling back and still resolve correctly.
      private def localization(values, code, override)
        declared_name_key = values.dig("Localization", "Name")
        own_name_key = "manufacturer_Name#{code}"
        own_desc_key = "manufacturer_Desc#{code}"

        # The block points somewhere else on purpose-looking-like-a-mistake only
        # when the export also defines this code's own name -- mxox.xml asks for
        # AEGS while `manufacturer_NameMXOX` sits right there. A code whose key
        # merely spells the company differently (GAM asking for GAMA) defines no
        # own key, so it is drift rather than a redirect and stays trusted.
        redirected = translations.key?(own_name_key) && declared_name_key != "@#{own_name_key}"

        name = if override["name"].present?
          override["name"]
        elsif translations.key?(own_name_key)
          translations[own_name_key]
        else
          translate(declared_name_key)
        end

        # A block that named another manufacturer names their description too.
        # FSKI and PRAR define none of their own, and inheriting Aegis' would put
        # its history on somebody else's page -- no description beats a wrong one.
        # Not read from the ",P" variant of the key, which is where the export
        # keeps most manufacturer descriptions: two thirds of the ones it would
        # unlock are unfinished stubs ("PH Octagon Description"), so pulling them
        # in wholesale would put placeholder text on the page. maxOx loses a real
        # description to that, which is the price of not shipping the other 22.
        description = if override["description"].present?
          override["description"]
        elsif translations.key?(own_desc_key)
          translations[own_desc_key]
        elsif override["name"].present? || redirected
          nil
        else
          translate(values.dig("Localization", "Description"))
        end

        [name, description]
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
