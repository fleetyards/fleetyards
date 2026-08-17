module ScData
  module Parser
    class CommoditiesParser < ScData::Parser::BaseParser
      NAME_PREFIX = "items_commodities_"
      TYPE_PREFIX = "items_commodities_type_"

      # Commodities are declared twice: once as a bare ResourceContainer under
      # entities/commodities, and once per crate size under scitem/carryables.
      # Together the two trees cover every purchasable commodity in the build.
      CANONICAL_PATH = "entities/commodities"
      SOURCE_PATHS = [CANONICAL_PATH, "entities/scitem/carryables"]

      # A handful of commodities are named after their own type key. Most are
      # real products (RMC, HPMC, the two fuels); this one is the generic label
      # the game puts on unmarked crates — evidence boxes, generic explosives —
      # so it would list "Processed Goods" alongside the goods themselves.
      IGNORED_KEYS = ["items_commodities_type_processedgoods"].freeze

      TYPE_SLUGS = {
        "agriculturalSupply" => "agricultural_supply",
        "alloy" => "alloy",
        "consumerGoods" => "consumer_goods",
        "drink" => "drink",
        "food" => "food",
        "gas" => "gas",
        "HPMC" => "hpmc",
        "manmade" => "manmade",
        "medicalSupply" => "medical_supply",
        "metal" => "metal",
        "militarySupply" => "military_supply",
        "Mineral" => "mineral",
        "natural" => "natural",
        "nonmetals" => "nonmetals",
        "plasmaFuel" => "plasma_fuel",
        "processedGoods" => "processed_goods",
        "quantumFuel" => "quantum_fuel",
        "RMC" => "rmc",
        "scrap" => "scrap",
        "vice" => "vice",
        "waste" => "waste"
      }.freeze

      CANONICAL_FOLDER_TYPES = {
        "agriculturalsupplies" => "agricultural_supply",
        "alloys" => "alloy",
        "consumergoods" => "consumer_goods",
        "counterfeit" => "consumer_goods",
        "food" => "food",
        "gas" => "gas",
        "halogens" => "nonmetals",
        "manmade" => "manmade",
        "medicalsupplies" => "medical_supply",
        "metals" => "metal",
        "minerals" => "mineral",
        "mixedmining" => "mineral",
        "natural" => "natural",
        "non_metals" => "nonmetals",
        "processedgoods" => "processed_goods",
        "scrap" => "scrap",
        "vice" => "vice",
        "waste" => "waste"
      }.freeze

      # Roughly a third of the commodities never declare a displayType — mostly
      # harvestables and tractor-beam-only crates. Their record path always names
      # the material, so fall back to it. Order is precedence: an ore crate lives
      # under a "metal_ore" path and must not be read as a mineral.
      PATH_TYPES = [
        [/trophy/, "natural"],
        [/_ore_/, "metal"],
        [/mineral/, "mineral"],
        [/_gas_/, "gas"],
        [/nonmetal/, "nonmetals"],
        [/special|holiday|lunar/, "consumer_goods"],
        [/processedgoods/, "processed_goods"],
        [/organic/, "food"],
        [/consumergoods/, "consumer_goods"],
        [/harvestable|_cy_/, "natural"]
      ].freeze

      def all
        parsed = commodities

        parsed.each { |commodity| save_icon(commodity[:icon]) }

        save_items(parsed, folder: "commodities")
      end

      def commodities
        records = Hash.new { |hash, key| hash[key] = new_record }

        load_commodity_data.each do |item|
          collect_record(records, item)
        end

        records.filter_map { |sc_key, record| parse_commodity(sc_key, record) }
      end

      private def new_record
        {types: Hash.new(0), canonical_type: nil, canonical_ref: nil, canonical_folder: nil, icons: [], paths: []}
      end

      private def collect_record(records, item)
        canonical = item[:path].start_with?(CANONICAL_PATH)

        purchasable_params(item[:values]).each do |params|
          sc_key = commodity_key(params["displayName"])

          next if sc_key.blank?
          next if IGNORED_KEYS.include?(sc_key)

          record = records[sc_key]
          record[:paths] << item[:path]

          if canonical
            record[:canonical_ref] ||= value_or_nil(item[:values].dig("__ref"))
            record[:canonical_folder] ||= canonical_folder(item[:path])
          end

          type = type_key(params["displayType"])

          if type.present?
            record[:types][type] += 1
            record[:canonical_type] ||= type if canonical
          end

          icon = value_or_nil(params["displayThumbnail"])
          record[:icons] << icon.downcase if icon.present?
        end
      end

      private def parse_commodity(sc_key, record)
        name = localize(sc_key)

        return if name.blank?

        type = resolve_type(record)

        {
          key: sc_key.delete_prefix(NAME_PREFIX),
          sc_key:,
          ref: record[:canonical_ref],
          name:,
          commodity_type: type,
          commodity_type_name: type_name(type),
          description: localize("#{sc_key}_desc"),
          icon: record[:icons].first
        }
      end

      # A record that declares the type under entities/commodities always wins:
      # crate records disagree with each other (the alloys are tagged both
      # "alloy" and "metal", contraband variants claim "vice"), and the bare
      # commodity record is the one the commodity kiosk reads.
      private def resolve_type(record)
        declared = record[:canonical_type] || record[:types].max_by { |_, count| count }&.first

        return TYPE_SLUGS[declared] if declared.present?

        CANONICAL_FOLDER_TYPES[record[:canonical_folder]] || type_from_paths(record[:paths])
      end

      private def canonical_folder(path)
        path.delete_prefix("#{CANONICAL_PATH}/").split("/").first
      end

      private def type_from_paths(paths)
        joined = paths.join(" ").downcase

        PATH_TYPES.find { |pattern, _| pattern.match?(joined) }&.last
      end

      private def type_name(type)
        return if type.blank?

        localize("#{TYPE_PREFIX}#{TYPE_SLUGS.key(type)}")
      end

      # The commodity display name occasionally points at the description key
      # instead of the name key (wuotan seed). Fall back to the base key so the
      # commodity doesn't end up named after a paragraph of flavour text.
      private def commodity_key(display_name)
        key = display_name.to_s.delete("@").sub(/,P\z/, "").downcase

        return unless key.start_with?(NAME_PREFIX)

        base_key = key.sub(/_desc\z/, "")

        commodity_translations.key?(base_key) ? base_key : key
      end

      # Localization keys are mixed case and some carry a ",P" plural marker,
      # while the record references are not consistently cased. Index both down.
      private def commodity_translations
        @commodity_translations ||= translations.each_with_object({}) do |(key, value), index|
          index[key.sub(/,P\z/, "").downcase] = value
        end
      end

      private def localize(key)
        # The index is downcased, so the lookup has to be too. Commodity keys
        # arrive downcased already, but the type keys are camel case
        # (@items_commodities_type_consumerGoods) and silently missed.
        value = commodity_translations[key.downcase]

        return if value.blank? || value == "@LOC_EMPTY"

        value.gsub('\\n', "\n").strip
      end

      private def type_key(display_type)
        key = display_type.to_s.delete("@").sub(/,P\z/, "")

        return unless key.start_with?(TYPE_PREFIX)

        key.delete_prefix(TYPE_PREFIX)
      end

      private def purchasable_params(values)
        params = values.dig("Components", "SCItemPurchasableParams")

        return [] if params.blank?

        params.is_a?(Array) ? params : [params]
      end

      private def load_commodity_data
        SOURCE_PATHS.flat_map do |path|
          Dir.glob("#{import_path}/#{path}/**/*.xml").filter_map do |file|
            content = File.read(file)

            next unless content.include?(NAME_PREFIX)

            {
              path: file.sub("#{import_path}/", ""),
              values: Hash.from_xml(content).values.first
            }
          end
        end
      end
    end
  end
end
