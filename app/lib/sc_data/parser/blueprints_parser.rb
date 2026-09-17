module ScData
  module Parser
    class BlueprintsParser < ScData::Parser::BaseParser
      SOURCE_PATH = "crafting/blueprints/crafting"

      # The stat each slot moves, as a record of its own. 29 exist in 4.10.1 and
      # 24 are referenced.
      PROPERTIES_PATH = "crafting/craftedproperties"

      # A cost names a ResourceType GUID, not a crate. This is the only place
      # that GUID is tied back to an `@items_commodities_*` key -- which is what
      # the commodity catalogue is keyed on, and why the join cannot go through
      # `Commodity#sc_ref`: that column comes from the crate entity and is null
      # for 100 of the 232 commodities, Iron among them.
      RESOURCE_TYPES_PATH = "resourcetypedatabase/resourcetypedatabase.records.xml"
      RESOURCE_TYPE = "ResourceType"

      COMMODITY_PREFIX = "items_commodities_"

      # Only the trees a crafted output has ever been found in. All 1603 outputs
      # that resolve in 4.10.1 live under one of them; scanning the whole of
      # `entities` to catch a hypothetical fifth would read 26,871 files for 15
      # that matter.
      ENTITY_PATH = "entities/scitem"

      # Which catalogue an output lands in, by where its entity record lives.
      # Ships first: a ship gun is `entities/scitem/ships/weapons`, and reading
      # it as personal equipment would file 125 turret and gun records as
      # something a player wears.
      OUTPUT_KINDS = [
        [%r{\Aentities/scitem/ships/}, "Component"],
        [%r{\Aentities/scitem/characters/}, "Equipment"],
        [%r{\Aentities/scitem/weapons/}, "Equipment"],
        [%r{\Aentities/scitem/carryables/}, "Commodity"]
      ].freeze

      # `_Linear` scales the stat, `_LinearIntegerAdditive` adds to it -- 5,069
      # against 150 in 4.10.1. Kept apart because the two cannot be rendered
      # with the same sentence.
      RAMPS = {
        "CraftingGameplayPropertyModifierValueRange_Linear" => "linear",
        "CraftingGameplayPropertyModifierValueRange_LinearIntegerAdditive" => "linear_integer_additive"
      }.freeze

      MODIFIER_PATH = [
        "context",
        "CraftingCostContext_ResultGameplayPropertyModifiers",
        "gameplayPropertyModifiers",
        "CraftingGameplayPropertyModifiers_List",
        "gameplayPropertyModifiers",
        "CraftingGameplayPropertyModifierCommon"
      ].freeze

      def all
        save_items(blueprints, folder: "blueprints")
      end

      def blueprints
        parsed = load_data(SOURCE_PATH).filter_map { |item| parse_blueprint(item[:key], item[:values]) }

        report_unknown_ramps

        parsed
      end

      # A ramp shape this does not know how to render is dropped, because a
      # number it cannot draw a line through is worse than no number. Said out
      # loud rather than dropped quietly: if CIG adds a third kind, the recipes
      # would otherwise keep parsing with their stats quietly missing.
      private def report_unknown_ramps
        return if unknown_ramps.empty?

        Rails.logger.warn(
          "[sc_data] BlueprintsParser: ignored #{unknown_ramps.values.sum} value ranges of " \
          "unknown kind: #{unknown_ramps.keys.sort.join(", ")}"
        )
      end

      private def unknown_ramps
        @unknown_ramps ||= Hash.new(0)
      end

      # One tier, one recipe: all 1607 records carry exactly one
      # `CraftingBlueprintTier` and exactly one `mandatoryCost`. A record that
      # breaks either is skipped rather than loaded as a recipe costing nothing.
      #
      # `optionalCost` exists in none of them, so it is not read.
      private def parse_blueprint(key, values)
        blueprint = values.dig("blueprint", "CraftingBlueprint")

        return if blueprint.blank?

        costs = Array.wrap(blueprint.dig("tiers", "CraftingBlueprintTier"))
          .first&.dig("recipe", "CraftingRecipe", "costs", "CraftingRecipeCosts")
        mandatory = costs&.dig("mandatoryCost", "CraftingCost_Select")

        return if mandatory.blank?

        {
          # Downcased so the key, the file it is written to and the slug a
          # loader derives all read the same. The records are the only ones in
          # the export named in upper case (`BP_CRAFT_klwe_smg_energy_01`).
          key: key.downcase,
          ref: value_or_nil(values["__ref"]),
          category_ref: value_or_nil(blueprint["category"]),
          craft_time: craft_time(costs["craftTime"]),
          # How many of the slots below a craft actually fills. Not always
          # three: 62 recipes take one, 442 two, 1072 three and 31 four.
          slot_count: mandatory["count"].to_i,
          output: output(blueprint),
          slots: slots(mandatory)
        }
      end

      private def craft_time(value)
        partitioned = value&.dig("TimeValue_Partitioned")

        return if partitioned.blank?

        (partitioned["days"].to_i * 1.day +
          partitioned["hours"].to_i * 1.hour +
          partitioned["minutes"].to_i * 1.minute +
          partitioned["seconds"].to_i).to_i
      end

      # What the recipe makes. A blueprint has no name of its own -- 1606 of
      # 1607 are `@LOC_PLACEHOLDER` -- so this is what the loader names it
      # after, which is why the entity is resolved here rather than left as a
      # GUID for the loader to chase.
      #
      # One output resolves to nothing: `bp_craft_cool_s04_cnou_pioneer` names
      # an entity class that is in no file in the export. It comes out as a ref
      # and nothing else rather than being dropped, so the loader can count it.
      private def output(blueprint)
        ref = value_or_nil(blueprint.dig("processSpecificData", "CraftingProcess_Creation", "entityClass"))

        return if ref.blank?

        path = entity_paths[ref]

        return {ref:} if path.blank?

        kind = OUTPUT_KINDS.find { |pattern, _| pattern.match?(path) }&.last

        details = entity_details(path)

        {
          ref:,
          key: entity_keys[ref],
          path:,
          kind:,
          # The name the loader falls back to. A component or a piece of
          # equipment is named by the row it links to, but four of the outputs
          # are mission carryables that are in no catalogue at all -- "Probe",
          # two "Metamaterial Test" samples and the TH-01 Propulsor -- and
          # without this they would load nameless.
          name: details[:name],
          # A carryable that is a commodity does not join on a ref: the column
          # comes from the crate entity and is null for 100 of the 232 rows.
          commodity_key: (details[:commodity_key] if kind == "Commodity")
        }.compact
      end

      private def slots(mandatory)
        Array.wrap(mandatory.dig("options", "CraftingCost_Select")).map.with_index do |slot, position|
          name_info = slot["nameInfo"] || {}
          debug_name = value_or_nil(name_info["debugName"])

          {
            position:,
            key: slot_key(debug_name),
            # The `@crafting_ui_slotname_*` key resolves for all 73 slots in
            # 4.10.1, but only through the ",P"-stripped index -- an exact
            # lookup misses every one of them. The debug name is the fallback
            # and reads almost as well ("ARMOURED CARAPACE").
            name: localize(name_info["displayName"]) || debug_name&.humanize,
            options: options(slot),
            modifiers: modifiers(slot)
          }
        end
      end

      private def slot_key(debug_name)
        return if debug_name.blank?

        # One slot is written "WIRING:" -- the colon is a typo in the record,
        # not a separator.
        debug_name.downcase.gsub(/[^a-z0-9]+/, "_").delete_prefix("_").delete_suffix("_").presence
      end

      # Every inner select has exactly one option today -- all 4,289 of them --
      # but the shape allows several, and the game already has the string for
      # it ("(Choose one material)"). Both kinds end at a commodity: a resource
      # through the resource database, an item through the carryable entity it
      # names.
      private def options(slot)
        resources = Array.wrap(slot.dig("options", "CraftingCost_Resource")).map do |resource|
          ref = value_or_nil(resource["resource"])

          {
            cost_type: "resource",
            ref:,
            commodity_key: resource_commodity_keys[ref],
            quantity: resource.dig("quantity", "SStandardCargoUnit", "standardCargoUnits")&.to_f,
            min_quality: resource["minQuality"]&.to_i
          }
        end

        items = Array.wrap(slot.dig("options", "CraftingCost_Item")).map do |item|
          ref = value_or_nil(item["entityClass"])

          {
            cost_type: "item",
            ref:,
            commodity_key: entity_details(entity_paths[ref])[:commodity_key],
            quantity: item["quantity"]&.to_f,
            min_quality: item["minQuality"]&.to_i
          }
        end

        (resources + items).map.with_index { |option, position| option.merge(position:) }
      end

      # How good the material has to be, and what it buys. Each modifier ramps
      # one stat over quality 0 to 1000; a record may carry several ranges for
      # one stat, so they are flattened into one list rather than nested.
      private def modifiers(slot)
        Array.wrap(slot.dig(*MODIFIER_PATH)).flat_map { |modifier|
          ref = value_or_nil(modifier["gameplayPropertyRecord"])
          property = properties[ref] || {}

          Array.wrap(modifier["valueRanges"]).flat_map do |ranges|
            ranges.flat_map do |type, values|
              ramp = RAMPS[type]

              if ramp.blank?
                unknown_ramps[type] += Array.wrap(values).size
                next []
              end

              Array.wrap(values).map do |range|
                {
                  ramp:,
                  property_ref: ref,
                  property_key: property[:key],
                  name: property[:name],
                  unit_format: property[:unit_format],
                  start_quality: range["startQuality"]&.to_i,
                  end_quality: range["endQuality"]&.to_i,
                  modifier_at_start: range["modifierAtStart"]&.to_f,
                  modifier_at_end: range["modifierAtEnd"]&.to_f
                }
              end
            end
          end
        }.map.with_index { |modifier, position| modifier.merge(position:) }
      end

      private def properties
        @properties ||= load_data(PROPERTIES_PATH).each_with_object({}) do |item, index|
          ref = value_or_nil(item[:values]["__ref"])

          next if ref.blank?

          index[ref] = {
            key: item[:key].downcase,
            name: localize(item[:values]["propertyName"]),
            unit_format: localize(item[:values]["unitFormat"])
          }
        end
      end

      private def resource_commodity_keys
        @resource_commodity_keys ||= resource_database.each_with_object({}) do |values, index|
          next unless values["__type"] == RESOURCE_TYPE

          ref = value_or_nil(values["__ref"])
          key = commodity_key(values["displayName"])

          index[ref] = key if ref.present? && key.present?
        end
      end

      private def resource_database
        @resource_database ||= begin
          root = Hash.from_xml(File.read("#{import_path}/#{RESOURCE_TYPES_PATH}")).values.first

          root.is_a?(Hash) ? root.each_value.flat_map { |values| Array.wrap(values) }.select { |values| values.is_a?(Hash) } : []
        rescue Errno::ENOENT
          []
        end
      end

      # What an entity calls itself. Its own attach definition first and the
      # purchase params only after, because those are copied along with the
      # entity when an artist clones a crate and regularly name something else.
      #
      # Memoized per path: the 1,606 resolved outputs, the 11 cost items and
      # the three outputs two blueprints share all come through here.
      private def entity_details(path)
        return {} if path.blank?

        @entity_details ||= {}
        @entity_details[path] ||= begin
          values = Hash.from_xml(File.read("#{import_path}/#{path}")).values.first

          names = Array.wrap(values.dig("Components", "SAttachableComponentParams")).flat_map { |params|
            Array.wrap(params["AttachDef"]).filter_map { |attach| attach.dig("Localization", "Name") }
          } + Array.wrap(values.dig("Components", "SCItemPurchasableParams")).map { |params| params["displayName"] }

          {
            name: names.lazy.filter_map { |name| localize(name) }.first,
            commodity_key: names.lazy.filter_map { |name| commodity_key(name) }.first
          }
        rescue Errno::ENOENT
          {}
        end
      end

      private def commodity_key(display_name)
        key = display_name.to_s.delete("@").sub(/,P\z/, "").downcase

        key if key.start_with?(COMMODITY_PREFIX)
      end

      private def entity_paths
        entity_index.first
      end

      private def entity_keys
        entity_index.last
      end

      # `__ref` to where the record lives, over the 24,113 item entities. The
      # root element is always the first line and never longer than 744
      # characters in 4.10.1, so this reads one line per file rather than
      # parsing 24,000 XML documents; anything that does not match falls back to
      # a real parse.
      private def entity_index
        @entity_index ||= begin
          paths = {}
          keys = {}

          Dir.glob("#{import_path}/#{ENTITY_PATH}/**/*.xml").each do |file|
            key, ref = entity_identity(file)

            next if ref.blank?

            path = file.sub("#{import_path}/", "")

            paths[ref] ||= path
            keys[ref] ||= key
          end

          [paths, keys]
        end
      end

      private def entity_identity(file)
        line = File.open(file, &:readline)
        match = line.match(/\A<([\w.]+)[^>]*?__ref="([0-9a-f-]{36})"/)

        return [match[1].split(".").last, match[2]] if match

        data = Hash.from_xml(File.read(file))

        [data.keys.first.split(".").last, value_or_nil(data.values.first["__ref"])]
      rescue EOFError, REXML::ParseException, ArgumentError
        []
      end
    end
  end
end
