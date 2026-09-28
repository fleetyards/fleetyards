module ScData
  module Parser
    # Where a contract takes place: on a planet or moon, in space, or either.
    #
    # No contract names a place. Each location slot (`PickupLocation_BP1`,
    # `MissionLocation_BP`, ...) holds a tag search, and the game picks a match
    # at run time from the `MissionLocationTemplate` records. So a slot's kind is
    # the kind of every location its search can match, and a contract's kind is
    # the union over its slots.
    #
    # A location says which it is through one tag, `LocationSetting/Surface` or
    # `LocationSetting/Space`: 1219 and 362 of the 2103 records in 4.10.1, and
    # none carries both. Most of the rest name a location type that settles it.
    # "Surface" means grounded, not strictly a planet: GrimHex, an asteroid
    # station, carries it too.
    class MissionLocations
      TAGS_PATH = "TagDatabase"
      LOCATIONS_PATH = "missiondata/pu_locations/templates"
      TEMPLATES_PATH = "contracts/contracttemplates"

      SETTING_PATH = "Missions/LocationType/LocationSetting"
      LOCATION_TYPE_PATH = "Missions/LocationType"

      # For a location without a LocationSetting tag. Only types that are one
      # or the other wherever they appear; a type that exists in both settings
      # (derelicts, hangars) is left out, and such a location stays unknown.
      SURFACE_TYPES = %w[
        Outpost AbandonedOutpost Cave Planet GroundBase SurfaceRelay Bunker Shelter
        RoofTop LandingZone Derelict_Ground DistributionCentre DistributionCentres
        UGF_OC Shanty_OC FloatingIsland ASD DrugBunker
      ].freeze
      SPACE_TYPES = %w[
        Station AsteroidCluster Asteroidfield AsteroidBase JumpPoint ShipGraveyard
        LagrangePoint OrbitalPlatform RestStop CommArray TheCollectorsAsteriod
      ].freeze

      # Tags a search names that no location record carries. The game resolves
      # them from where a location is placed on the starmap, which the export
      # does not link, so matching on them would find nothing.
      #
      # Lagrange tags are the exception worth keeping: they only ever name space.
      LAGRANGE = "LagrangePoints"

      # A contract whose only work is in a ship: it spawns ships, and nothing
      # that puts a pilot on foot or at a door. Its location can be a surface
      # point of interest while the fight happens in flight.
      SHIP_SPAWNS = "MissionPropertyValue_ShipSpawnDescriptions"
      GROUND_WORK = %w[
        MissionPropertyValue_NPCSpawnDescriptions
        MissionPropertyValue_MissionItem
        MissionPropertyValue_HaulingOrders
        MissionPropertyValue_EntitySpawnDescriptions
      ].freeze

      def initialize(loader)
        @loader = loader
      end

      # `{location_kind:, needs_landing:}` for one contract under its handler.
      # `needs_landing` is only true when a pilot has to set down: a surface or
      # mixed location, and work that is not ship combat alone.
      def classify(contract, handler)
        properties = merged_properties(contract, handler)
        kinds = properties.values.filter_map { |value| slot_kind(value) }.flatten.uniq
        kind = contract_kind(kinds)

        {
          location_kind: kind,
          needs_landing: %w[surface mixed].include?(kind) && !ship_combat_only?(properties)
        }
      end

      private def contract_kind(kinds)
        kinds -= ["unknown"]
        return "unknown" if kinds.empty?
        return "mixed" if kinds.include?("surface") && kinds.include?("space")

        kinds.first
      end

      private def ship_combat_only?(properties)
        types = properties.values.flat_map { |value| value.is_a?(Hash) ? value.keys : [] }

        types.include?(SHIP_SPAWNS) && (types & GROUND_WORK).empty?
      end

      # Template first, then the handler's, then the contract's own, each later
      # one replacing a slot of the same name: that is the order the game
      # applies overrides in.
      private def merged_properties(contract, handler)
        template = templates[value_or_nil(contract["template"])] || {}

        [
          template,
          properties_of(handler&.dig("contractParams", "propertyOverrides")),
          properties_of(contract.dig("paramOverrides", "propertyOverrides"))
        ].reduce({}) { |merged, layer| merged.merge(layer) }
      end

      private def properties_of(node)
        Array.wrap(node&.dig("MissionProperty")).each_with_object({}) do |property, result|
          next unless property.is_a?(Hash)

          name = property["missionVariableName"].presence || property.object_id.to_s
          result[name] = property["value"]
        end
      end

      # `nil` for a slot that is not a location. A `Locations` slot (a set of
      # them) is classified the same way.
      private def slot_kind(value)
        return unless value.is_a?(Hash)

        search = value["MissionPropertyValue_Location"] || value["MissionPropertyValue_Locations"]
        return if search.nil?

        conditions = Array.wrap(search.is_a?(Hash) ? search.dig("matchConditions", "DataSetMatchCondition_TagSearch") : nil)
          .select { |condition| condition.is_a?(Hash) }
        return ["unknown"] if conditions.empty?

        direct = direct_kinds(conditions)
        return direct if direct.any?

        matched = locations.select { |location| conditions.all? { |condition| matches?(location, condition) } }
        kinds = matched.map { |location| location[:kind] || "unknown" }.uniq

        kinds.empty? ? ["unknown"] : kinds
      end

      # A search that names the setting, a Lagrange point or a location type
      # that is only ever one of the two says the kind outright. That also
      # covers searches that match no record, because the rest of their tags
      # are placement tags.
      private def direct_kinds(conditions)
        conditions.flat_map { |condition| terms(condition) }.flat_map do |term|
          names = term[:positive].map { |id| tag_path(id) }

          names.filter_map do |path|
            next "surface" if path == "#{SETTING_PATH}/Surface"
            next "space" if path == "#{SETTING_PATH}/Space" || path.include?("/#{LAGRANGE}")

            type_kind(path)
          end
        end.uniq
      end

      private def type_kind(path)
        return unless path.start_with?("#{LOCATION_TYPE_PATH}/")

        type = path.delete_prefix("#{LOCATION_TYPE_PATH}/").split("/").first
        return "surface" if SURFACE_TYPES.include?(type)

        "space" if SPACE_TYPES.include?(type)
      end

      # Tags AND'd within a term, terms OR'd; placement-only tags dropped.
      private def matches?(location, condition)
        pool = case condition["tagType"]
        when "Produces" then location[:produces]
        when "Consumes" then location[:consumes]
        else location[:general]
        end

        terms(condition).any? do |term|
          positive = term[:positive].select { |id| known_tags.include?(id) }
          negative = term[:negative].select { |id| known_tags.include?(id) }

          positive.all? { |id| pool.include?(id) } && negative.none? { |id| pool.include?(id) }
        end
      end

      private def terms(condition)
        Array.wrap(condition.dig("tagSearch", "TagSearchTerm")).select { |term| term.is_a?(Hash) }.map do |term|
          {
            positive: refs(term["positiveTags"]),
            negative: refs(term["negativeTags"])
          }
        end
      end

      private def refs(node)
        Array.wrap(node.is_a?(Hash) ? node["Reference"] : nil).filter_map { |ref| value_or_nil(ref["value"]) if ref.is_a?(Hash) }
      end

      private def locations
        @locations ||= @loader.call(LOCATIONS_PATH).filter_map do |item|
          data = item[:values]["locationData"] || {}
          next if data["disabled"] == "1"

          general = refs(data.dig("generalTags", "tags"))

          {
            general: with_ancestors(general),
            produces: with_ancestors(refs(data.dig("producesTags", "tags"))),
            consumes: with_ancestors(refs(data.dig("consumesTags", "tags"))),
            kind: location_kind(general)
          }
        end
      end

      private def location_kind(ids)
        paths = ids.map { |id| tag_path(id) }

        return "surface" if paths.include?("#{SETTING_PATH}/Surface")
        return "space" if paths.include?("#{SETTING_PATH}/Space")

        kinds = paths.filter_map { |path| type_kind(path) }.uniq

        kinds.first if kinds.one?
      end

      # Every tag some location carries, with its ancestors: what a search can
      # actually match on.
      private def known_tags
        @known_tags ||= locations.flat_map { |location| [*location[:general], *location[:produces], *location[:consumes]] }.to_set
      end

      private def templates
        @templates ||= @loader.call(TEMPLATES_PATH).each_with_object({}) do |item, result|
          ref = value_or_nil(item[:values]["__ref"])
          result[ref] = properties_of(item[:values]["contractProperties"]) if ref
        end
      end

      private def with_ancestors(ids)
        ids.flat_map { |id| ancestors(id) }.to_set
      end

      private def ancestors(id)
        @ancestors ||= {}
        @ancestors[id] ||= begin
          chain = []
          current = id
          while current && chain.exclude?(current)
            chain << current
            current = tag_parents[current]
          end
          chain
        end
      end

      private def tag_path(id)
        ancestors(id).reverse.map { |tag| tag_names[tag] }.join("/")
      end

      private def tag_names
        tag_tree
        @tag_names
      end

      private def tag_parents
        tag_tree
        @tag_parents
      end

      private def tag_tree
        return if @tag_names

        @tag_names = {}
        @tag_parents = {}

        @loader.call(TAGS_PATH).each do |item|
          item[:values].each do |key, value|
            next unless key.to_s.start_with?("Tag.")

            Array.wrap(value).each do |tag|
              next unless tag.is_a?(Hash)

              @tag_names[tag["__ref"]] = tag["tagName"]
              Array.wrap(tag.dig("children", "Reference")).each do |child|
                @tag_parents[child["value"]] = tag["__ref"] if child.is_a?(Hash)
              end
            end
          end
        end
      end

      private def value_or_nil(value)
        value.presence unless value == "00000000-0000-0000-0000-000000000000"
      end
    end
  end
end
