module ScData
  module Parser
    # Where a crafting blueprint comes from.
    #
    # A blueprint is referenced by nothing outside `crafting/` except the reward
    # pools, and a pool is referenced only by a GUID -- grepping the contract
    # tree for a pool's name finds nothing at all. So the chain has to be walked
    # by ref, in two shapes:
    #
    #   pool <- ContractGenerator > handler > CareerContract > BlueprintRewards
    #   pool <- rox_scenarioprogress > tierRewards > blueprintPool > Reference
    #
    # One JSON per pool rather than per blueprint: a pool is the entity the game
    # actually models, 154 of them against 1607 recipes, and the loader is what
    # fans it out.
    class ContractsParser < ScData::Parser::BaseParser
      POOLS_PATH = "crafting/blueprintrewards"
      GENERATORS_PATH = "contracts/contractgenerator"
      # Two record sets, because the two chains arrive at an org differently. A
      # contract generator names the `FactionReputation` directly; the scenario
      # names a `Faction`, whose own name is `@LOC_UNINITIALIZED` and which
      # carries `factionReputationRef` to the record that is named.
      FACTIONS_PATH = "factions"
      FACTION_REPUTATION = "FactionReputation"
      FACTION = "Faction"
      STANDINGS_PATH = "reputation/standings"

      # The only thing the export says about which side of the law an org sits
      # on, and it is a boolean: all 38 reputation records state it. There is no
      # third state anywhere in the tree to read instead -- `Faction.factionType`
      # only ever reads Lawful, Unlawful, PrivateSecurity or LawEnforcement, and
      # `_RepUI_Area` is prose that says "UEE" for Vaughn, an assassination
      # broker. So a neutral org is a curation call, made by the loader against
      # `org_key`, and this carries the half the game is willing to state.
      LAWFUL_PROPERTY = "entityLawful"

      # The one scenario that hands out blueprints without going through a
      # contract generator: XenoThreat, whose reward tiers name a pool each.
      SCENARIO_PATH = "contracts/contractscenarios/rox_scenarioprogress.xml"

      # Six handler shapes exist and four of them carry a blueprint pool.
      # Walking only `_Career` -- the one with 215 of the 272 handlers -- found
      # 74 of the 105 pools a contract generator hands out.
      #
      # `SubContract` is deliberately not a contract kind: it is a step inside
      # one, and its rewards are the parent contract's.
      CONTRACT_KINDS = %w[CareerContract Contract].freeze

      POOLS_FOLDER = "blueprint_pools"

      def all
        parsed = pools

        # `save_items` returns before it clears, so a run that parsed nothing
        # leaves the previous catalogue on disk. That is deliberate for `items`
        # and `models`, which several passes fill and where an early blank pass
        # must not wipe what a later one writes -- but this folder is written
        # once, so blank means the crafting tree is gone rather than not reached
        # yet.
        #
        # Left alone, the stale pools would still clear the floor check and load
        # as the current build's sources, which is the one failure the check
        # exists to catch.
        return clear_once("#{export_path}/#{POOLS_FOLDER}") if parsed.blank?

        save_items(parsed, folder: POOLS_FOLDER)
      end

      def pools
        sources = pool_sources

        load_data(POOLS_PATH).filter_map do |item|
          values = item[:values]
          ref = value_or_nil(values["__ref"])

          next if ref.blank?

          {
            key: item[:key].downcase,
            ref:,
            # `blueprintmissionpools`, `ors`, `xenothreat2rewards`,
            # `collectorwikelo`, `48blueprints` -- the folder is the only
            # grouping the export gives a pool.
            group: pool_group(values),
            blueprints: rewards(values),
            sources: sources[ref] || []
          }
        end
      end

      private def rewards(values)
        Array.wrap(values.dig("blueprintRewards", "BlueprintReward")).filter_map do |reward|
          ref = value_or_nil(reward["blueprintRecord"])

          next if ref.blank?

          # Every one of the 818 entries in 4.10.1 weighs 1, so nothing can be
          # said about relative odds yet. Carried anyway because the field is
          # the only place the game could ever say otherwise.
          {ref:, weight: reward["weight"]&.to_f}
        end
      end

      private def pool_group(values)
        path = value_or_nil(values["__path"]).to_s

        path[%r{blueprintrewards/([^/]+)/}, 1]
      end

      # Pool ref to everything that hands that pool out. Built once: the
      # generator tree is 107 files and the walk is the expensive half.
      private def pool_sources
        @pool_sources ||= begin
          sources = Hash.new { |all, ref| all[ref] = [] }

          collect_generator_sources(sources)
          collect_scenario_sources(sources)

          sources.transform_values { |entries| entries.uniq.map.with_index { |entry, position| entry.merge(position:) } }
        end
      end

      # A generator carries one handler per system -- Stanton and Pyro are
      # separate records with the same org -- and under each, one
      # `CareerContract` per difficulty. The pool hangs off the contract's
      # results, so the title and the standing band that reach it are that
      # contract's own.
      private def collect_generator_sources(sources)
        load_data(GENERATORS_PATH).each do |item|
          fallback = generator_org(item[:values])

          handlers(item[:values]).each do |handler|
            org_ref = value_or_nil(handler["factionReputation"]) || fallback

            org = orgs[org_ref] || {}

            contracts(handler).each do |contract|
              entry = {
                kind: "contract",
                org_ref:,
                org_key: org[:key],
                org_name: org[:name],
                org_lawful: org[:lawful],
                generator_key: item[:key].downcase,
                mission_name: contract_title(contract),
                min_standing: standings[value_or_nil(contract["minStanding"])],
                max_standing: standings[value_or_nil(contract["maxStanding"])]
              }.compact

              contract_pools(contract).each { |ref| sources[ref] << entry }
            end
          end
        end
      end

      # A `_List` handler states no faction of its own, so the org has to come
      # from the rest of the record -- eleven pool-bearing handlers are in that
      # position, the Bounty Hunters Guild's FPS contracts among them.
      #
      # Only where the whole generator names exactly one: a file that names two
      # would be a guess, and a wrong org is worse here than none, since "who
      # gives me this" is the entire question the source answers.
      private def generator_org(values)
        refs = faction_refs(values).uniq

        refs.first if refs.one?
      end

      # Walked rather than scanned out of the re-serialised XML: `Hash#to_xml`
      # writes every attribute as an element, so a regex for
      # `factionReputation="..."` matches nothing at all.
      private def faction_refs(node)
        case node
        when Hash
          node.flat_map do |key, value|
            next [value_or_nil(value)].compact if key == "factionReputation"

            faction_refs(value)
          end
        when Array
          node.flat_map { |entry| faction_refs(entry) }
        else
          []
        end
      end

      # Every handler under `generators`, whatever its shape.
      private def handlers(values)
        (values["generators"] || {}).flat_map { |name, handler|
          next [] unless name.start_with?("ContractGeneratorHandler_")

          Array.wrap(handler)
        }.select { |handler| handler.is_a?(Hash) }
      end

      private def contracts(handler)
        CONTRACT_KINDS.flat_map { |kind| Array.wrap(handler.dig("contracts", kind)) }
          .select { |contract| contract.is_a?(Hash) }
      end

      # The mission as a player reads it -- "Yellow Level Contract: Ambush An
      # Amateur". `debugName` is the other candidate and is not for reading.
      private def contract_title(contract)
        params = Array.wrap(contract.dig("paramOverrides", "stringParamOverrides", "ContractStringParam"))
        title = params.find { |param| param["param"] == "Title" }

        localize(title&.dig("value"))
      end

      # Walked rather than dug at a fixed depth. `contractResults` nests a
      # different number of levels depending on the contract shape, and a dig
      # that assumes one of them silently returns nothing for the others --
      # which is how walking only `_Career` looked like it was working.
      private def contract_pools(contract)
        pool_refs(contract).uniq
      end

      private def pool_refs(node)
        case node
        when Hash
          node.flat_map do |key, value|
            next Array.wrap(value).filter_map { |reward| value_or_nil(reward["blueprintPool"]) } if key == "BlueprintRewards"

            pool_refs(value)
          end
        when Array
          node.flat_map { |entry| pool_refs(entry) }
        else
          []
        end
      end

      # XenoThreat hands its pools out by scenario progress rather than by
      # contract: a reward tier names the pools and the points that unlock them.
      private def collect_scenario_sources(sources)
        file = "#{import_path}/#{SCENARIO_PATH}"

        return unless File.exist?(file)

        values = Hash.from_xml(File.read(file)).values.first

        Array.wrap(values.dig("factionRewardTiers", "SScenarioProgressRewardsTiers")).each do |tier_set|
          org_ref = value_or_nil(tier_set["faction"])
          org = orgs[org_ref] || {}

          Array.wrap(tier_set.dig("tierProgressions", "STierProgressions")).each do |progression|
            Array.wrap(progression.dig("tierRewards", "STierReward")).each do |tier|
              entry = {
                kind: "scenario",
                org_ref:,
                org_key: org[:key],
                org_name: org[:name],
                org_lawful: org[:lawful],
                scenario_key: File.basename(SCENARIO_PATH, ".xml"),
                min_points: tier["minPoints"]&.to_i
              }.compact

              Array.wrap(tier.dig("blueprintPool", "Reference")).each do |reference|
                ref = value_or_nil(reference["value"])

                sources[ref] << entry if ref.present?
              end
            end
          end
        end
      end

      # The org that hands a contract out, keyed by every ref either chain can
      # arrive with. All 38 reputation records resolve, but only through the
      # ",P"-stripped index -- `@Foxwell_RepUI_Name` is declared in another case.
      private def orgs
        @orgs ||= begin
          records = load_data(FACTIONS_PATH).filter_map { |item|
            ref = value_or_nil(item[:values]["__ref"])

            [ref, item] if ref.present?
          }.to_h

          named = records.each_with_object({}) do |(ref, item), index|
            next unless item[:values]["__type"] == FACTION_REPUTATION

            index[ref] = {
              # `factionreputation_wikelo`, from the record's own element name.
              # The loader curates neutrality against this rather than against
              # the GUID, which is an identity the export is free to reissue,
              # or the display name, which is localised.
              key: item[:key].downcase,
              name: localize(item[:values]["displayName"]),
              lawful: lawful(item[:values])
            }
          end

          # A `Faction` is a wrapper: its own name is `@LOC_UNINITIALIZED` and
          # it states no `entityLawful` at all, so it takes the reputation
          # record's entry whole rather than half of it.
          records.each do |ref, item|
            next unless item[:values]["__type"] == FACTION

            org = named[value_or_nil(item[:values]["factionReputationRef"])]

            named[ref] = org if org.present?
          end

          named
        end
      end

      # Walked rather than dug: `propertiesBB` carries one entry per UI field
      # and `entityLawful` sits at a different index per record, so the entry
      # has to be found by name.
      private def lawful(values)
        property = Array.wrap(values.dig("propertiesBB", "SReputationContextBBPropertyParams"))
          .find { |entry| entry.is_a?(Hash) && entry["name"] == LAWFUL_PROPERTY }

        stated = property&.dig("dynamicProperty", "SBBDynamicPropertyBool", "value")

        return if stated.blank?

        stated == "1"
      end

      # "Neutral", "Elite Contractor" -- the band a contract is offered in,
      # which is the rank a player reads as VHRT and up.
      private def standings
        @standings ||= load_data(STANDINGS_PATH).each_with_object({}) do |item, index|
          values = item[:values]
          ref = value_or_nil(values["__ref"])

          next if ref.blank?

          # `name` here is a debug string -- "FactionRep_Allied_Rank1" -- and
          # `displayName` is the one a player is shown.
          index[ref] = localize(values["displayName"])
        end
      end
    end
  end
end
