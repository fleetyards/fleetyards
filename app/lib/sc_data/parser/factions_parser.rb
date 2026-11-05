module ScData
  module Parser
    # The orgs a player earns standing with, and the ladders they climb there.
    #
    # A faction's ladders come from two places that disagree. Its UI context
    # lists the scopes the game shows for it, and its contracts name the scopes
    # their awards feed: all of Foxwell's awards feed the general standing
    # ladder, which its context does not list. Either alone would hide a ladder
    # a player is on.
    class FactionsParser < ScData::Parser::BaseParser
      include ScData::Parser::ReputationLadders

      FACTIONS_PATH = "factions/factionreputation"
      CONTEXTS_PATH = "reputation/contexts"
      GENERATORS_PATH = "contracts/contractgenerator"
      FOLDER = "factions"

      FACTION_REPUTATION = "FactionReputation"
      AWARD = "contractResultReputationAmounts"

      # Every faction carries this one, so it says nothing about what sets a
      # faction apart and reads last.
      AFFINITY_LADDER = "reputationscope_affinity"

      TEXT_PROPERTIES = {
        description: "entityDescription",
        headquarters: "entityHeadquarters",
        founded: "entityFounded",
        leadership: "entityLeadership",
        area: "entityArea",
        focus: "entityFocus"
      }.freeze
      LAWFUL_PROPERTY = "entityLawful"

      def all
        parsed = factions

        return clear_once("#{export_path}/#{FOLDER}") if parsed.blank?

        # `ManufacturerLogos` holds these beside the manufacturers' own, which
        # that parser has already written and a clear here would delete.
        parsed.each { |faction| save_icon(faction[:icon], clear: false) if faction[:icon].present? }

        save_items(parsed, folder: FOLDER, key: :sc_key)
      end

      def factions
        load_data(FACTIONS_PATH).filter_map do |item|
          parse_faction(item[:key], item[:values])
        end
      end

      private def parse_faction(key, values)
        return unless values["__type"] == FACTION_REPUTATION

        ref = value_or_nil(values["__ref"])
        name = value_or_nil(localize(values["displayName"]))

        # Two records in the export are unnamed stubs, and a page with no name
        # is not one a reader could recognise.
        return if ref.blank? || name.blank?

        {
          sc_key: key.downcase,
          sc_ref: ref,
          name:,
          lawful: lawful(values),
          icon: asset_path(value_or_nil(values["logo"]))&.downcase,
          **TEXT_PROPERTIES.transform_values { |property| text_property(values, property) },
          ladders: ladders(ref, values)
        }
      end

      # The scopes awards feed come first, those most awards name first, so the
      # ladder a faction's contracts mostly pay into leads. Unique by what a reader would see:
      # Northrock's context lists two scopes with the same name and ranks.
      private def ladders(ref, values)
        awarded = awarded_scopes.fetch(ref, {}).sort_by { |_scope, count| -count }.map(&:first)

        scopes = (awarded + context_scopes(values))
          .uniq
          .filter_map { |scope| reputation_scopes[scope] }
          .select { |ladder| ladder[:name].present? && ladder[:ranks].any? }
          .uniq { |ladder| ladder.slice(:name, :ranks) }

        affinity, others = scopes.partition { |ladder| ladder[:key] == AFFINITY_LADDER }

        (others + affinity).map { |ladder| ladder.slice(:key, :name, :ceiling, :ranks) }
      end

      private def context_scopes(values)
        context = contexts[value_or_nil(values["reputationContextPropertiesUI"])]

        return [] if context.blank?

        listed = Array.wrap(context.dig("scopeContextList", "SReputationScopeContextUI"))

        [context["primaryScopeContext"], *listed].filter_map do |entry|
          value_or_nil(entry["scope"]) if entry.is_a?(Hash)
        end
      end

      private def contexts
        @contexts ||= load_data(CONTEXTS_PATH).each_with_object({}) do |item, index|
          ref = value_or_nil(item[:values]["__ref"])

          index[ref] = item[:values] if ref.present?
        end
      end

      # Faction ref to the scopes its awards feed, with how many name each.
      private def awarded_scopes
        @awarded_scopes ||= begin
          counts = Hash.new { |all, faction| all[faction] = Hash.new(0) }

          load_data(GENERATORS_PATH).each { |item| collect_awards(item[:values], counts) }

          counts
        end
      end

      private def collect_awards(node, counts)
        case node
        when Hash
          node.each do |key, value|
            if key == AWARD
              Array.wrap(value).each { |award| count_award(award, counts) }
            else
              collect_awards(value, counts)
            end
          end
        when Array
          node.each { |entry| collect_awards(entry, counts) }
        end
      end

      private def count_award(award, counts)
        faction = value_or_nil(award["factionReputation"])
        scope = value_or_nil(award["reputationScope"])

        counts[faction][scope] += 1 if faction.present? && scope.present?
      end

      # Found by name: `propertiesBB` holds one entry per UI field, at a
      # different index per record.
      private def property(values, name)
        Array.wrap(values.dig("propertiesBB", "SReputationContextBBPropertyParams"))
          .find { |entry| entry.is_a?(Hash) && entry["name"] == name }
          &.fetch("dynamicProperty", nil)
      end

      private def text_property(values, name)
        key = property(values, name)&.dig("SBBDynamicPropertyLocString", "value")

        value_or_nil(localize(key))
      end

      private def lawful(values)
        stated = property(values, LAWFUL_PROPERTY)&.dig("SBBDynamicPropertyBool", "value")

        return if stated.blank?

        stated == "1"
      end
    end
  end
end
