module ScData
  module Parser
    # The contract generator tree, read for two catalogues.
    #
    # `game_missions` is a record per contract -- who offers it, the standing it
    # takes, its difficulty and what it rewards. `blueprint_pools` is where a
    # crafting blueprint comes from, which is the older of the two and the
    # reason the walk exists at all:
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
    #
    # Both outputs come off one traversal of the 107 generator files, which is
    # the expensive half of either.
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
      CONTRACT_KINDS = {"CareerContract" => "career", "Contract" => "contract"}.freeze

      # Where the payout, the standing and the items a contract awards are
      # declared. `ContractResult_CalculatedReward` is not among them on
      # purpose: it is an empty element on all 2352 contracts that carry it,
      # because the game computes that figure at run time and the export states
      # no table, curve or scalar it could be computed from here.
      REPUTATION_REWARDS_PATH = "reputation/rewards"
      DIFFICULTY_PROFILES_PATH = "contracts/contractdifficultyprofiles"

      # A difficulty band is a designer's sentence with the level on the end --
      # "Hard_PvE_or_Easy_PvP_action_5", "Basically_a_Dev_7". The prose is
      # developer-facing and the 1-7 is the only half worth showing, so the
      # number is what is carried and the label is ours.
      DIFFICULTY_AXES = {
        mechanical_skill: "mechanicalSkill",
        mental_load: "mentalLoad",
        risk_of_loss: "riskOfLoss",
        game_knowledge: "gameKnowledge"
      }.freeze

      # What `@LOC_UNINITIALIZED` resolves to. It is a real entry in the
      # localisation file rather than a missing key, so `localize` returns it
      # happily and a contract that has never been titled would otherwise ship
      # "<= UNINITIALIZED =>" as its name.
      UNINITIALIZED = "<= UNINITIALIZED =>"

      POOLS_FOLDER = "blueprint_pools"
      MISSIONS_FOLDER = "game_missions"

      def all
        save_pools
        save_missions
      end

      # `save_items` returns before it clears, so a run that parsed nothing
      # leaves the previous catalogue on disk. That is deliberate for `items`
      # and `models`, which several passes fill and where an early blank pass
      # must not wipe what a later one writes -- but these folders are written
      # once, so blank means the tree is gone rather than not reached yet.
      #
      # Left alone, the stale records would still clear the floor check and
      # load as the current build's, which is the one failure the check exists
      # to catch.
      private def save_pools
        parsed = pools

        return clear_once("#{export_path}/#{POOLS_FOLDER}") if parsed.blank?

        save_items(parsed, folder: POOLS_FOLDER)
      end

      private def save_missions
        parsed = missions

        return clear_once("#{export_path}/#{MISSIONS_FOLDER}") if parsed.blank?

        save_items(parsed, folder: MISSIONS_FOLDER, key: :sc_key)
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
        contract_entries.each do |entry|
          contract = entry[:contract]
          org = entry[:org]

          source = {
            kind: "contract",
            org_ref: entry[:org_ref],
            org_key: org[:key],
            org_name: org[:name],
            org_lawful: org[:lawful],
            generator_key: entry[:generator_key],
            mission_name: contract_title(contract),
            min_standing: standings[value_or_nil(contract["minStanding"])],
            max_standing: standings[value_or_nil(contract["maxStanding"])]
          }.compact

          contract_pools(contract).each { |ref| sources[ref] << source }
        end
      end

      # Every contract in the generator tree, with its handler's org already
      # resolved. Memoised because both catalogues read it and the traversal --
      # 107 files, one `Hash.from_xml` each -- is what either of them costs.
      private def contract_entries
        @contract_entries ||= load_data(GENERATORS_PATH).flat_map do |item|
          fallback = generator_org(item[:values])

          handlers(item[:values]).flat_map do |handler|
            org_ref = value_or_nil(handler["factionReputation"]) || fallback

            contracts(handler).map do |kind, contract|
              {
                generator_key: item[:key].downcase,
                kind:,
                contract:,
                org_ref:,
                org: orgs[org_ref] || {}
              }
            end
          end
        end
      end

      # One record per contract. 2536 of them in 4.10.1, against the 786 that
      # hand out a blueprint and are the only ones the pool walk keeps.
      def missions
        identified = contract_entries.filter_map do |entry|
          sc_ref = value_or_nil(entry[:contract]["id"])

          [entry, sc_ref, mission_base(entry, sc_ref)] if sc_ref.present?
        end

        # Counted before a single key is handed out, so that whether a key is
        # suffixed depends on the set of contracts rather than on the order
        # they were walked in.
        shared = identified.map(&:last).tally

        identified.map do |entry, sc_ref, base|
          contract = entry[:contract]
          org = entry[:org]

          {
            sc_key: (shared[base] > 1) ? "#{base}_#{sc_ref.delete("-").first(8)}" : base,
            sc_ref:,
            kind: entry[:kind],
            generator_key: entry[:generator_key],
            debug_name: value_or_nil(contract["debugName"]),
            title: contract_title(contract),
            # Kept as the export writes it, `~mission(Location|Address)` spans
            # and all: the game fills those in from the mission it generates,
            # and deleting them here breaks the sentence around them.
            description: contract_param(contract, "Description"),
            org_ref: entry[:org_ref],
            org_key: org[:key],
            org_name: org[:name],
            org_lawful: org[:lawful],
            min_standing: standings[value_or_nil(contract["minStanding"])],
            max_standing: standings[value_or_nil(contract["maxStanding"])],
            released: released?(contract),
            difficulty: difficulty(contract),
            rewards: contract_rewards(contract),
            blueprint_pools: contract_pools(contract)
          }.compact
        end
      end

      # `generator_key` alone repeats, and `debugName` alone collides across
      # generators, so the key is both. That still leaves 13 bases shared by two
      # contracts each in 4.10.1.
      #
      # `missions` suffixes *every* member of a shared base with the head of its
      # GUID, rather than letting the first one keep the bare base. Nothing
      # fixes the order `Dir.glob` walks the generators in, so "the first one"
      # is not a property of the contract: were two to swap between builds, the
      # loader -- which finds a row by `sc_ref` -- would try to write one row the
      # `sc_key` the other still holds, and the unique index would stop the load
      # rather than the two exchanging URLs.
      #
      # The three contracts with no `debugName` fall back to the GUID whole.
      private def mission_base(entry, sc_ref)
        debug_name = value_or_nil(entry[:contract]["debugName"])

        return sc_ref if debug_name.blank?

        sanitize_key("#{entry[:generator_key]}_#{debug_name}")
      end

      # A `debugName` is a developer's note and not an identifier: 64 of them
      # carry a space, a bracket, a dash or a slash. The key becomes a file
      # name, so the slash is the one that matters --
      # `TheCollector_SB_JungleArm(DO_NOT_USE_NOW_LOOT)` merely reads oddly,
      # while `shubin_rg_discovery_fpsmine_pyro/nyx_rank3_...` writes into a
      # directory `save_items` never created.
      #
      # `-` is kept, which is what leaves this collision-free: flattening the
      # other four characters adds no pair to the 13 the raw keys already share.
      private def sanitize_key(key)
        key.downcase.gsub(/[^a-z0-9_-]+/, "_").gsub(/\A_+|_+\z/, "")
      end

      # Two flags, both of which mean the contract is in the files but not in
      # front of a player: 348 are `notForRelease` and 21 `workInProgress`.
      private def released?(contract)
        contract["notForRelease"] != "1" && contract["workInProgress"] != "1"
      end

      # The band sits under `contractResults` rather than on the contract, at
      # whatever depth that contract's results nest to, so it is found by name.
      private def difficulty(contract)
        values = Array.wrap(find_node(contract["contractResults"], "ContractDifficulty")).first

        return if values.blank?

        bands = DIFFICULTY_AXES.to_h { |name, attribute| [name, band_level(values[attribute])] }

        bands.merge(profile: difficulty_profiles[value_or_nil(values["difficultyProfile"])]).compact.presence
      end

      private def band_level(value)
        value.to_s[/_(\d+)\z/, 1]&.to_i
      end

      # The first node declared with `key`, at any depth. `contractResults`
      # nests a different number of levels depending on the contract shape, and
      # a dig that assumes one of them silently returns nothing for the others.
      private def find_node(node, key)
        case node
        when Hash
          return node[key] if node.key?(key)

          node.each_value do |value|
            found = find_node(value, key)

            return found if found
          end

          nil
        when Array
          node.each do |entry|
            found = find_node(entry, key)

            return found if found
          end

          nil
        end
      end

      # Profile ref to the record's own element name -- "general", "logistics",
      # "discovery". The weights it carries are how the game turns the four
      # bands into a payout, and are deliberately not copied onto every mission.
      private def difficulty_profiles
        @difficulty_profiles ||= load_data(DIFFICULTY_PROFILES_PATH).each_with_object({}) do |item, index|
          ref = value_or_nil(item[:values]["__ref"])

          index[ref] = item[:key].downcase if ref.present?
        end
      end

      # What the export is willing to state. Walked rather than dug, for the
      # same reason the pool refs are: `contractResults` nests a different
      # number of levels per contract shape.
      private def contract_rewards(contract)
        collect_rewards(contract["contractResults"])
      end

      private def collect_rewards(node)
        case node
        when Hash
          node.flat_map { |key, value| reward_entries(key, value) || collect_rewards(value) }
        when Array
          node.flat_map { |entry| collect_rewards(entry) }
        else
          []
        end
      end

      # Returns nil rather than an empty array for anything that is not a
      # reward, so the walk knows to keep descending. A reward element's own
      # children are never descended into: they are `missionResults` booleans.
      private def reward_entries(key, value)
        case key
        when "ContractResult_Reward" then currency_rewards(value)
        when "ContractResult_LegacyReputation" then reputation_rewards(value)
        when "ContractResult_Item" then item_rewards(value)
        when "ContractResult_ItemsWeighting" then weighted_item_rewards(value)
        when "ContractResult_BadgeAward" then badge_rewards(value)
        end
      end

      # The only stated payout in the game files: 8 contracts across the whole
      # tree, one of them in mercenary scrip rather than aUEC. A `max` of zero
      # is the field's unset value and not a ceiling of nothing.
      private def currency_rewards(value)
        Array.wrap(value).filter_map do |result|
          reward = result["contractReward"]

          next if reward.blank?

          max = reward["max"].to_i

          {
            kind: "currency",
            amount: reward["reward"]&.to_i,
            max: (max if max.positive?),
            currency: value_or_nil(reward["currencyType"])
          }.compact
        end
      end

      private def reputation_rewards(value)
        Array.wrap(value).flat_map do |result|
          Array.wrap(result["contractResultReputationAmounts"]).filter_map do |amounts|
            amount = reputation_amounts[value_or_nil(amounts["reward"])]

            next if amount.nil?

            org = orgs[value_or_nil(amounts["factionReputation"])] || {}

            {kind: "reputation", amount:, org_key: org[:key], org_name: org[:name]}.compact
          end
        end
      end

      private def item_rewards(value)
        Array.wrap(value).filter_map do |result|
          entity_class = value_or_nil(result["entityClass"])

          next if entity_class.blank?

          {kind: "item", entity_class:, amount: result["amount"]&.to_i}.compact
        end
      end

      # One reward drawn from several weighted sets, each of which awards
      # everything in it. Flattened to one entry per entity class carrying its
      # set's weight, because a set is not a thing the catalogue can show.
      private def weighted_item_rewards(value)
        Array.wrap(value).flat_map do |result|
          Array.wrap(result.dig("itemAwardStructure", "ItemAwardWeightings")).flat_map do |weighting|
            Array.wrap(weighting.dig("awards", "ItemAwardEntityClass")).filter_map do |award|
              entity_class = value_or_nil(award["entityClass"])

              next if entity_class.blank?

              {kind: "item", entity_class:, amount: award["amountToAward"]&.to_i, weight: weighting["weighting"]&.to_f}.compact
            end
          end
        end
      end

      private def badge_rewards(value)
        Array.wrap(value).filter_map do |result|
          badge = value_or_nil(result["badgeToAward"])

          {kind: "badge", badge:} if badge.present?
        end
      end

      # Reward ref to the number of reputation points it is worth. 58 records,
      # from -640000 to +640000, and a contract names one rather than stating a
      # figure of its own.
      private def reputation_amounts
        @reputation_amounts ||= load_data(REPUTATION_REWARDS_PATH).each_with_object({}) do |item, index|
          values = item[:values]
          ref = value_or_nil(values["__ref"])
          amount = values["reputationAmount"]

          index[ref] = amount.to_i if ref.present? && amount.present?
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

      # Walked rather than dug at `contracts`. A handler puts most of them
      # there and some elsewhere -- `introContracts` holds the mission an org
      # hands out first, `PVPBountyContract` the NorthRock duels -- which is 23
      # contracts across 12 generators, five of them handing out a blueprint.
      #
      # Paired with the kind, because the element name is the only place a
      # contract says which of the two it is. A found contract is not descended
      # into, so a nested one is never mistaken for a sibling.
      private def contracts(handler)
        contract_nodes(handler)
      end

      private def contract_nodes(node)
        case node
        when Hash
          node.flat_map do |key, value|
            kind = CONTRACT_KINDS[key]

            next contract_nodes(value) if kind.blank?

            Array.wrap(value).select { |contract| contract.is_a?(Hash) }.map { |contract| [kind, contract] }
          end
        when Array
          node.flat_map { |entry| contract_nodes(entry) }
        else
          []
        end
      end

      # The mission as a player reads it -- "Yellow Level Contract: Ambush An
      # Amateur". `debugName` is the other candidate and is not for reading.
      private def contract_title(contract)
        contract_param(contract, "Title")
      end

      private def contract_param(contract, name)
        params = Array.wrap(contract.dig("paramOverrides", "stringParamOverrides", "ContractStringParam"))
        param = params.find { |entry| entry["param"] == name }

        value = localize(param&.dig("value"))

        value unless value == UNINITIALIZED
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
