# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class ContractsParserTest < ActiveSupport::TestCase
      RECORDS_PATH = "Data/Libs/Foundry/Records"

      POOL_REF = "af21edb5-3938-45ac-8a35-130e52463f44"
      BLUEPRINT_REF = "6157c081-0a9b-4319-bbbc-7f2cc1ef7158"
      ORG_REF = "016c2950-0292-468c-a408-a5283b52f158"
      FACTION_REF = "21c61135-e8ee-459c-8f61-4550b8c02c58"
      RANK0_REF = "a8f635c5-7fc0-4d27-8a08-27bb3476bfb8"
      RANK6_REF = "426da095-27b1-4ac3-8722-af57a973c79c"
      CONTRACT_ID = "3f2a4d41-0000-4000-8000-000000000001"
      SECOND_CONTRACT_ID = "7b91cc05-0000-4000-8000-000000000002"
      PROFILE_REF = "9c0a1f22-0000-4000-8000-0000000000a1"
      REPUTATION_REWARD_REF = "9c0a1f22-0000-4000-8000-0000000000b1"
      TITLE_KEY = "@Foxwell_ShipAmbush_VE_title_001"
      ENTITY_REF = "5d1e0c3a-0000-4000-8000-0000000000c1"
      RESOURCE_REF = "5d1e0c3a-0000-4000-8000-0000000000c2"
      AWARD_RECORD_REF = "5d1e0c3a-0000-4000-8000-0000000000c3"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        @parser = ::ScData::Parser::ContractsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "#pools reads a pool and the blueprints it hands out" do
        pool("bp_missionreward_foxwellenforcement_ambush", group: "blueprintmissionpools")

        pools = @parser.pools

        assert_equal 1, pools.size
        assert_equal "bp_missionreward_foxwellenforcement_ambush", pools.first[:key]
        assert_equal "blueprintmissionpools", pools.first[:group]
        assert_equal [BLUEPRINT_REF], pools.first[:blueprints].pluck(:ref)
        assert_equal [1.0], pools.first[:blueprints].pluck(:weight)
      end

      # The whole chain, by ref: nothing names a pool by its key, so a grep for
      # one over the contract tree finds nothing at all.
      test "#pools walks a pool back to the org, the mission and the standing band" do
        translate(
          "Foxwell_RepUI_Name" => "Foxwell Enforcement",
          "Foxwell_ShipAmbush_VE_title_001" => "Yellow Level Contract: Ambush An Amateur",
          "mobiGlas_Reputation_Stance_Neutral" => "Neutral",
          "RepScope_Contractor_Rank6" => "Elite Contractor"
        )
        faction_reputation("foxwellenforcement", ref: ORG_REF, display_name: "@Foxwell_RepUI_Name")
        standing("rank0", ref: RANK0_REF, display_name: "@mobiGlas_Reputation_Stance_Neutral")
        standing("rank6", ref: RANK6_REF, display_name: "@RepScope_Contractor_Rank6")
        pool("bp_missionreward_foxwellenforcement_ambush")
        generator("foxwellenforcement_ambush")

        source = @parser.pools.first[:sources].first

        assert_equal "contract", source[:kind]
        assert_equal "Foxwell Enforcement", source[:org_name]
        assert_equal "Yellow Level Contract: Ambush An Amateur", source[:mission_name]
        assert_equal "Neutral", source[:min_standing]
        assert_equal "Elite Contractor", source[:max_standing]
        assert_equal "foxwellenforcement_ambush", source[:generator_key]
      end

      # A standing carries a debug `name` -- "FactionRep_Allied_Rank1" -- beside
      # the `displayName` a player is shown. Reading the wrong one leaves every
      # band blank, because the debug string is in no localisation file.
      test "#pools takes a standing's display name rather than its debug name" do
        translate("RepScope_Contractor_Rank6" => "Elite Contractor")
        standing("rank6", ref: RANK6_REF, display_name: "@RepScope_Contractor_Rank6", name: "FactionRep_Allied_Rank6")
        pool("bp_pool")
        generator("gen", min_standing: RANK6_REF, max_standing: RANK6_REF)

        assert_equal "Elite Contractor", @parser.pools.first[:sources].first[:max_standing]
      end

      # `entityLawful` sits in `propertiesBB` behind a name, at a different index
      # per record, so it has to be found rather than dug at a fixed depth.
      test "#pools reads the org's lawful flag and its record key" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement")
        faction_reputation("factionreputation_lawful_foxwellenforcement",
          ref: ORG_REF, display_name: "@Foxwell_RepUI_Name", lawful: true)
        pool("bp_pool")
        generator("gen")

        source = @parser.pools.first[:sources].first

        assert_equal "factionreputation_lawful_foxwellenforcement", source[:org_key]
        assert source[:org_lawful]
      end

      # `false` has to survive the `.compact` the entry goes through, or an
      # outlaw org would arrive indistinguishable from one the export says
      # nothing about.
      test "#pools keeps an unlawful org's flag rather than compacting it away" do
        translate("HeadHunters_RepUI_Name" => "Headhunters")
        faction_reputation("factionreputation_unlawful_headhunters",
          ref: ORG_REF, display_name: "@HeadHunters_RepUI_Name", lawful: false)
        pool("bp_pool")
        generator("gen")

        source = @parser.pools.first[:sources].first

        assert_includes source, :org_lawful
        assert_equal false, source[:org_lawful]
      end

      test "#pools leaves the lawful flag out where the record states none" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement")
        faction_reputation("factionreputation_lawful_foxwellenforcement",
          ref: ORG_REF, display_name: "@Foxwell_RepUI_Name")
        pool("bp_pool")
        generator("gen")

        source = @parser.pools.first[:sources].first

        assert_equal "Foxwell Enforcement", source[:org_name]
        assert_not_includes source, :org_lawful
      end

      # A `Faction` states no `entityLawful` of its own -- it is a wrapper whose
      # own name is @LOC_UNINITIALIZED -- so it has to take the reputation
      # record's entry whole rather than only the name off it.
      test "#pools carries the lawful flag through a faction wrapper" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement")
        faction_reputation("factionreputation_lawful_foxwellenforcement",
          ref: ORG_REF, display_name: "@Foxwell_RepUI_Name", lawful: true)
        faction("lawful_foxwellenforcement", ref: FACTION_REF, reputation_ref: ORG_REF)
        pool("bp_rewards_xenothreat2_15_01", group: "xenothreat2rewards")
        scenario(faction_ref: FACTION_REF, min_points: 18_000)

        source = @parser.pools.first[:sources].first

        assert_equal "factionreputation_lawful_foxwellenforcement", source[:org_key]
        assert source[:org_lawful]
      end

      # The scenario names a `Faction`, whose own name is @LOC_UNINITIALIZED and
      # which carries `factionReputationRef` to the record that is named.
      test "#pools resolves the scenario's org through the faction reputation it points at" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement")
        faction_reputation("foxwellenforcement", ref: ORG_REF, display_name: "@Foxwell_RepUI_Name")
        faction("lawful_foxwellenforcement", ref: FACTION_REF, reputation_ref: ORG_REF)
        pool("bp_rewards_xenothreat2_15_01", group: "xenothreat2rewards")
        scenario(faction_ref: FACTION_REF, min_points: 18_000)

        source = @parser.pools.first[:sources].first

        assert_equal "scenario", source[:kind]
        assert_equal "Foxwell Enforcement", source[:org_name]
        assert_equal 18_000, source[:min_points]
        assert_nil source[:mission_name]
      end

      # Six handler shapes exist and four carry a pool. Walking only `_Career`
      # found 74 of the 105 pools a generator hands out.
      test "#pools reads a pool from a handler that is not a career handler" do
        pool("bp_pool")
        generator("listed", handler: "ContractGeneratorHandler_List", contract_kind: "Contract")

        assert_equal 1, @parser.pools.first[:sources].size
      end

      # A `_List` handler states no faction of its own, so the org comes from
      # the rest of the record -- but only where that is unambiguous.
      test "#pools takes the generator's org for a handler that states none" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement")
        faction_reputation("foxwellenforcement", ref: ORG_REF, display_name: "@Foxwell_RepUI_Name")
        pool("bp_pool")
        generator("listed", handler: "ContractGeneratorHandler_List", contract_kind: "Contract", org_ref: nil, sibling_org: ORG_REF)

        assert_equal "Foxwell Enforcement", @parser.pools.first[:sources].first[:org_name]
      end

      test "#pools leaves the org blank where the generator names two" do
        pool("bp_pool")
        generator("ambiguous", handler: "ContractGeneratorHandler_List", contract_kind: "Contract",
          org_ref: nil, sibling_org: ORG_REF, second_org: FACTION_REF)

        assert_nil @parser.pools.first[:sources].first[:org_name]
      end

      test "#pools keeps a pool nothing hands out" do
        pool("bp_rewards_ors_example", group: "ors")

        assert_empty @parser.pools.first[:sources]
      end

      test "#missions emits a record per contract with its title, org and standing band" do
        translate(
          "Foxwell_RepUI_Name" => "Foxwell Enforcement",
          "Foxwell_ShipAmbush_VE_title_001" => "Yellow Level Contract: Ambush An Amateur",
          "Foxwell_ShipAmbush_VE_desc_001" => "Somebody needs teaching a lesson.",
          "mobiGlas_Reputation_Stance_Neutral" => "Neutral",
          "RepScope_Contractor_Rank6" => "Elite Contractor"
        )
        faction_reputation("foxwellenforcement", ref: ORG_REF, display_name: "@Foxwell_RepUI_Name", lawful: true)
        standing("rank0", ref: RANK0_REF, display_name: "@mobiGlas_Reputation_Stance_Neutral")
        standing("rank6", ref: RANK6_REF, display_name: "@RepScope_Contractor_Rank6")
        generator("foxwellenforcement", debug_name: "Ambush_VeryEasy", description: "@Foxwell_ShipAmbush_VE_desc_001")

        missions = @parser.missions

        assert_equal 1, missions.size
        assert_equal "foxwellenforcement_ambush_veryeasy", missions.first[:sc_key]
        assert_equal CONTRACT_ID, missions.first[:sc_ref]
        assert_equal "career", missions.first[:kind]
        assert_equal "Yellow Level Contract: Ambush An Amateur", missions.first[:title]
        assert_equal "Somebody needs teaching a lesson.", missions.first[:description]
        assert_equal "Foxwell Enforcement", missions.first[:org_name]
        assert missions.first[:org_lawful]
        assert_equal "Neutral", missions.first[:min_standing]
        assert_equal "Elite Contractor", missions.first[:max_standing]
        assert missions.first[:released]
        assert_equal [POOL_REF], missions.first[:blueprint_pools]
      end

      # A handler puts most of its contracts under `contracts` and some under
      # `introContracts` or `PVPBountyContract`. Digging at the first key alone
      # lost 23 contracts, five of which hand out a blueprint.
      test "#missions reads a contract a handler files somewhere other than contracts" do
        generator("adagio", container: "introContracts", contract_kind: "Contract", debug_name: "Adagio_Intro")

        assert_equal "adagio_adagio_intro", @parser.missions.sole[:sc_key]
      end

      # Every member of a shared base takes the suffix, including the first.
      # `Dir.glob` fixes no order between builds, so "the first one" is not a
      # property of the contract -- and were two to swap, the loader would try
      # to write one row the key the other still holds and the unique index
      # would stop the load rather than the two exchanging URLs.
      test "#missions suffixes every contract sharing a generator and a debug name" do
        generator("headhunters", debug_name: "Simple_Hit", contract_ids: [CONTRACT_ID, SECOND_CONTRACT_ID])

        keys = @parser.missions.pluck(:sc_key)

        assert_equal 2, keys.size
        assert_not_includes keys, "headhunters_simple_hit"
        assert_includes keys, "headhunters_simple_hit_#{CONTRACT_ID.delete("-")}"
        assert_includes keys, "headhunters_simple_hit_#{SECOND_CONTRACT_ID.delete("-")}"
      end

      # A fixed-length head of the GUID is only probably unique, and the failure
      # is quiet: `save_items` writes both records to one file name and one
      # contract silently replaces the other.
      test "#missions keeps two contracts apart whose GUIDs share a long prefix" do
        twin = "3f2a4d41-0000-4000-8000-00000000ffff"
        generator("headhunters", debug_name: "Simple_Hit", contract_ids: [CONTRACT_ID, twin])

        keys = @parser.missions.pluck(:sc_key)

        assert_equal 2, keys.uniq.size
      end

      # The key a contract gets depends on the set of contracts, never on the
      # order they were walked in: the same two, the other way round, are the
      # same two keys.
      test "#missions gives a contract the same key whichever order it is walked in" do
        generator("headhunters", debug_name: "Simple_Hit", contract_ids: [CONTRACT_ID, SECOND_CONTRACT_ID])
        forwards = @parser.missions.to_h { |mission| [mission[:sc_ref], mission[:sc_key]] }

        FileUtils.rm_rf("#{@raw_path}/#{RECORDS_PATH}/contracts")

        reversed_parser = ::ScData::Parser::ContractsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
        @parser = reversed_parser
        generator("headhunters", debug_name: "Simple_Hit", contract_ids: [SECOND_CONTRACT_ID, CONTRACT_ID])

        backwards = reversed_parser.missions.to_h { |mission| [mission[:sc_ref], mission[:sc_key]] }

        assert_equal forwards, backwards
      end

      # A `debugName` is a developer's note: 64 carry a space, a bracket, a dash
      # or a slash, and the key becomes a file name. The slash is the one that
      # matters -- it wrote into a directory `save_items` never created.
      test "#missions flattens a debug name that would write into a directory" do
        generator("shubin", debug_name: "Discovery_Pyro/Nyx Rank3 (Low)")

        assert_equal "shubin_discovery_pyro_nyx_rank3_low", @parser.missions.sole[:sc_key]
      end

      test "#missions marks a contract the build is not offering" do
        generator("tarpits", released: false)

        assert_equal false, @parser.missions.sole[:released]
      end

      # The band is a designer's sentence with the level on the end, and it sits
      # under `contractResults` rather than on the contract.
      test "#missions reads the difficulty bands as levels and keeps the profile" do
        difficulty_profile("general")
        generator("gen", difficulty: {
          mechanicalSkill: "Hard_PvE_or_Easy_PvP_action_5",
          mentalLoad: "AFK_gaming_1",
          riskOfLoss: "Safe_and_sound_zzzz_1",
          gameKnowledge: "Basically_a_Dev_7"
        })

        difficulty = @parser.missions.sole[:difficulty]

        assert_equal 5, difficulty[:mechanical_skill]
        assert_equal 1, difficulty[:mental_load]
        assert_equal 1, difficulty[:risk_of_loss]
        assert_equal 7, difficulty[:game_knowledge]
        assert_equal "general", difficulty[:profile]
      end

      test "#missions reads the payout the few contracts that state one carry" do
        generator("gen", results: %(<ContractResult_Reward><contractReward reward="3000" max="5000" currencyType="MER" /></ContractResult_Reward>))

        reward = @parser.missions.sole[:rewards].sole

        assert_equal "currency", reward[:kind]
        assert_equal 3000, reward[:amount]
        assert_equal 5000, reward[:max]
        assert_equal "MER", reward[:currency]
      end

      # Seven of the eight state `max="0"`, which is the field unset rather than
      # a ceiling of nothing.
      test "#missions leaves out a maximum of zero" do
        generator("gen", results: %(<ContractResult_Reward><contractReward reward="40000" max="0" currencyType="UEC" /></ContractResult_Reward>))

        reward = @parser.missions.sole[:rewards].sole

        assert_equal 40_000, reward[:amount]
        assert_not_includes reward, :max
      end

      # A contract names a reward record rather than stating a figure, and the
      # record is in another tree entirely.
      test "#missions resolves a reputation reward to the amount its record states" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement")
        faction_reputation("foxwellenforcement", ref: ORG_REF, display_name: "@Foxwell_RepUI_Name")
        reputation_reward("reputationrewardamount_positive_xxxs", ref: REPUTATION_REWARD_REF, amount: 100)
        generator("gen", results: <<~XML)
          <ContractResult_LegacyReputation>
            <contractResultReputationAmounts factionReputation="#{ORG_REF}" reward="#{REPUTATION_REWARD_REF}" />
          </ContractResult_LegacyReputation>
        XML

        reward = @parser.missions.sole[:rewards].sole

        assert_equal "reputation", reward[:kind]
        assert_equal 100, reward[:amount]
        assert_equal "Foxwell Enforcement", reward[:org_name]
      end

      # 2352 of the 2536 contracts award this and it is an empty element on every
      # one of them. Its presence is still the answer to "does this pay at all",
      # which is a different question from "how much" -- and 176 contracts
      # answer it no, so the distinction is worth carrying.
      test "#missions says a calculated reward pays, without inventing a figure" do
        generator("gen", results: %(<ContractResult_CalculatedReward><missionResults><Bool value="1" /></missionResults></ContractResult_CalculatedReward>))

        reward = @parser.missions.sole[:rewards].sole

        assert_equal "currency", reward[:kind]
        assert reward[:calculated]
        assert_not_includes reward, :amount
      end

      # A contract declares one result per outcome, so the same computed payout
      # is found several times over. It says one thing however many times it is
      # stated.
      test "#missions states a calculated payout once however often it is declared" do
        results = 3.times.map { %(<ContractResult_CalculatedReward><missionResults><Bool value="1" /></missionResults></ContractResult_CalculatedReward>) }.join
        generator("gen", results:)

        assert_equal 1, @parser.missions.sole[:rewards].count { |reward| reward[:calculated] }
      end

      test "#missions leaves the rewards empty for a contract that states none" do
        generator("gen", results: "")

        assert_empty @parser.missions.sole[:rewards]
      end

      test "#missions names an item reward from the entity it awards" do
        translate("Item_Palatino_Helmet" => "Palatino Helmet Mark I")
        named_entity("entities/scitem/characters/palatino_helmet", ref: ENTITY_REF, name: "@Item_Palatino_Helmet")
        generator("gen", results: %(<ContractResult_Item entityClass="#{ENTITY_REF}" amount="1" />))

        assert_equal "Palatino Helmet Mark I", @parser.missions.sole[:rewards].sole[:entity_name]
      end

      # A vehicle is an actor, and Wikelo hands out ATLS variants.
      test "#missions names a reward defined under the actor tree" do
        translate("TheCollector_Mod_ATLS_Name" => "ATLS Orange Line")
        named_entity("actor/actors/argo_atls_collector", ref: ENTITY_REF, name: "@TheCollector_Mod_ATLS_Name")
        generator("gen", results: %(<ContractResult_Item entityClass="#{ENTITY_REF}" amount="1" />))

        assert_equal "ATLS Orange Line", @parser.missions.sole[:rewards].sole[:entity_name]
      end

      test "#missions follows a weighted award stated as a record of its own" do
        write("contracts/contractrewards/iawr_foodorderreward", "ItemAwardWeightingsRecord", AWARD_RECORD_REF, <<~XML)
          <itemAwardStructure>
            <ItemAwardWeightings weighting="1">
              <awards>
                <ItemAwardEntityClass amountToAward="2" entityClass="#{ENTITY_REF}" />
              </awards>
            </ItemAwardWeightings>
          </itemAwardStructure>
        XML
        generator("gen", results: <<~XML)
          <ContractResult_ItemsWeighting>
            <itemAwardStructure>
              <ItemAwardWeightingsParams awardsRecord="#{AWARD_RECORD_REF}" />
            </itemAwardStructure>
          </ContractResult_ItemsWeighting>
        XML

        reward = @parser.missions.sole[:rewards].sole

        assert_equal ENTITY_REF, reward[:entity_class]
        assert_equal 2, reward[:amount]
        assert_equal 1.0, reward[:weight]
      end

      test "#missions reads what a contract asks to be brought to it" do
        translate("Item_Yormandi_Eye" => "Yormandi Eye")
        named_entity("entities/carryables/yormandi_eye", ref: ENTITY_REF, name: "@Item_Yormandi_Eye")
        generator("gen", properties: hand_in_property(
          %(<HaulingOrderContent_EntityClass entityClass="#{ENTITY_REF}" minAmount="14" maxAmount="0" />)
        ))

        hand_in = @parser.missions.sole[:hand_ins].sole

        assert_equal "item", hand_in[:kind]
        assert_equal ENTITY_REF, hand_in[:entity_class]
        assert_equal "Yormandi Eye", hand_in[:entity_name]
        assert_equal 14, hand_in[:amount]
        assert_not_includes hand_in, :max
        assert_not_includes hand_in, :option
      end

      # Ranta Dung has no `Localization` node and names itself only through
      # its purchase params.
      test "#missions names a commodity hand-in from its purchase params" do
        translate("items_commodities_rantadung" => "Ranta Dung")
        write("entities/commodities/rantadung", "EntityClassDefinition", ENTITY_REF, <<~XML)
          <Components>
            <SCItemPurchasableParams displayName="@items_commodities_rantadung" />
          </Components>
        XML
        generator("gen", properties: hand_in_property(
          %(<HaulingOrderContent_EntityClass entityClass="#{ENTITY_REF}" minAmount="15" maxAmount="15" />)
        ))

        hand_in = @parser.missions.sole[:hand_ins].sole

        assert_equal "Ranta Dung", hand_in[:entity_name]
        assert_equal "items_commodities_rantadung", hand_in[:commodity_key]
      end

      test "#missions names a hand-in that accepts any of a group" do
        translate("Salvage_SRT_Cannister_Name" => "SRT Canister")
        write("entities/haulingentityclass/haulingentityclass_srt", "Hauling_EntityClasses", ENTITY_REF, "",
          orderDisplayName: "@Salvage_SRT_Cannister_Name")
        generator("gen", properties: hand_in_property(
          %(<HaulingOrderContent_EntityClasses haulingEntityClasses="#{ENTITY_REF}" minAmount="1" maxAmount="4" />)
        ))

        hand_in = @parser.missions.sole[:hand_ins].sole

        assert_equal "SRT Canister", hand_in[:entity_name]
        assert_equal 1, hand_in[:amount]
        assert_equal 4, hand_in[:max]
      end

      test "#missions reads a resource hand-in in SCU and the choice a contract offers" do
        translate("items_commodities_quartz" => "Quartz")
        resource_types(%(<ResourceType.Quartz displayName="@items_commodities_quartz" __type="ResourceType" __ref="#{RESOURCE_REF}" />))
        generator("gen", properties: hand_in_property(<<~XML))
          <HaulingOrderContent_Or>
            <options>
              <HaulingOrder_OrOption_And>
                <orders>
                  <HaulingOrderContent_Resource resource="#{RESOURCE_REF}" maxContainerSize="-1" minSCU="2" maxSCU="2" />
                </orders>
              </HaulingOrder_OrOption_And>
              <HaulingOrder_OrOption_And>
                <orders>
                  <HaulingOrderContent_EntityClass entityClass="#{ENTITY_REF}" minAmount="5" maxAmount="5" />
                </orders>
              </HaulingOrder_OrOption_And>
            </options>
          </HaulingOrderContent_Or>
        XML

        resource, item = @parser.missions.sole[:hand_ins]

        assert_equal ["resource", "Quartz", RESOURCE_REF, 2, 0], resource.values_at(:kind, :resource_name, :resource_ref, :amount, :option)
        assert_equal "items_commodities_quartz", resource[:commodity_key]
        assert_equal ["item", 5, 1], item.values_at(:kind, :amount, :option)
      end

      test "#missions skips an order that asks for none of something" do
        generator("gen", properties: hand_in_property(
          %(<HaulingOrderContent_EntityClass entityClass="#{ENTITY_REF}" minAmount="0" maxAmount="4" />)
        ))

        assert_empty @parser.missions.sole[:hand_ins]
      end

      test "#missions leaves the hand-ins empty for a contract that asks for nothing" do
        generator("gen")

        assert_empty @parser.missions.sole[:hand_ins]
      end

      test "#missions reads the buy-in, the time it takes and how it comes round again" do
        generator("gen", results_attributes: %(contractBuyInAmount="1000" timeToComplete="7.8"), extra: <<~XML)
          <generationParams>
            <ContractGenerationParams_Legacy maxInstances="-1" maxInstancesPerPlayer="1" respawnTime="5" respawnTimeVariation="2" />
          </generationParams>
        XML

        mission = @parser.missions.sole

        assert_equal [1000, 7.8, 1, 5.0, 2.0],
          mission.values_at(:buy_in, :time_to_complete, :max_instances_per_player, :respawn_time, :respawn_variation)
      end

      # Zero is the field unset, and -1 instances per player is no limit.
      test "#missions leaves out terms the contract leaves unset" do
        generator("gen", results_attributes: %(contractBuyInAmount="0" timeToComplete="0"), extra: <<~XML)
          <generationParams>
            <ContractGenerationParams_Legacy maxInstancesPerPlayer="-1" respawnTime="0" respawnTimeVariation="0" />
          </generationParams>
        XML

        mission = @parser.missions.sole

        %i[buy_in time_to_complete max_instances_per_player respawn_time respawn_variation].each do |key|
          assert_not_includes mission, key
        end
      end

      test "#missions reads a crime stat band and a reputation band with another org" do
        translate("Foxwell_RepUI_Name" => "Foxwell Enforcement", "RepScope_Contractor_Rank6" => "Elite Contractor")
        faction_reputation("foxwellenforcement", ref: ORG_REF, display_name: "@Foxwell_RepUI_Name")
        standing("rank6", ref: RANK6_REF, display_name: "@RepScope_Contractor_Rank6")
        crime = %(<defaultAvailability><prerequisites><ContractPrerequisite_CrimeStat minCrimeStat="0" maxCrimeStat="2" /></prerequisites></defaultAvailability>)
        generator("gen", handler_extra: crime, extra: <<~XML)
          <additionalPrerequisites>
            <ContractPrerequisite_Reputation factionReputation="#{ORG_REF}" exclude="1" minStanding="#{RANK6_REF}" maxStanding="#{RANK6_REF}" />
          </additionalPrerequisites>
        XML

        reputation, crime_stat = @parser.missions.sole[:prerequisites]

        assert_equal ["reputation", "Foxwell Enforcement", "Elite Contractor", true],
          reputation.values_at(:kind, :org_name, :min_standing, :excluded)
        assert_equal ["crime_stat", 0, 2], crime_stat.values_at(:kind, :min, :max)
      end

      # A tag is granted by the contracts whose results carry it, so the
      # requirement arrives as those contracts rather than as the tag.
      test "#missions resolves a completed-missions requirement to the contracts that grant it" do
        tag = "5d1e0c3a-0000-4000-8000-0000000000d1"
        generator("granter", contract_ids: [SECOND_CONTRACT_ID], results: <<~XML)
          <ContractResult_CompletionTags>
            <completionTags>
              <ContractResult_CompletionTag count="1" tag="#{tag}" />
            </completionTags>
          </ContractResult_CompletionTags>
        XML
        generator("gen", extra: <<~XML)
          <additionalPrerequisites>
            <ContractPrerequisite_CompletedContractTags requiredCountValue="5" excludedCountValue="1">
              <requiredCompletedContractTags><tags><Reference value="#{tag}" /></tags></requiredCompletedContractTags>
              <excludedCompletedContractTags><tags><Reference value="#{tag}" /></tags></excludedCompletedContractTags>
            </ContractPrerequisite_CompletedContractTags>
          </additionalPrerequisites>
        XML

        required, excluded = @parser.missions.find { |mission| mission[:sc_ref] == CONTRACT_ID }[:prerequisites]

        assert_equal ["completed_missions", 5, [SECOND_CONTRACT_ID]], required.values_at(:kind, :count, :mission_refs)
        assert_equal ["excluded_missions", 1, [SECOND_CONTRACT_ID]], excluded.values_at(:kind, :count, :mission_refs)
      end

      test "#missions carries a contract that grants what it asks for as a flag, not a link to itself" do
        tag = "5d1e0c3a-0000-4000-8000-0000000000d2"
        generator("gen", results: <<~XML, extra: <<~PREREQUISITES)
          <ContractResult_CompletionTags>
            <completionTags>
              <ContractResult_CompletionTag count="1" tag="#{tag}" />
            </completionTags>
          </ContractResult_CompletionTags>
        XML
          <additionalPrerequisites>
            <ContractPrerequisite_CompletedContractTags requiredCountValue="1" excludedCountValue="1">
              <excludedCompletedContractTags><tags><Reference value="#{tag}" /></tags></excludedCompletedContractTags>
            </ContractPrerequisite_CompletedContractTags>
          </additionalPrerequisites>
        PREREQUISITES

        excluded = @parser.missions.sole[:prerequisites].sole

        assert_equal ["excluded_missions", [], true], excluded.values_at(:kind, :mission_refs, :includes_self)
      end

      test "#missions lists the places a contract is offered at" do
        locality_place = "5d1e0c3a-0000-4000-8000-0000000000e1"
        place = "5d1e0c3a-0000-4000-8000-0000000000e2"
        locality = "5d1e0c3a-0000-4000-8000-0000000000e3"
        write("missiondata/pu_missionlocality/stanton1", "MissionLocality", locality,
          %(<availableLocations><Reference value="#{locality_place}" /></availableLocations>))
        generator("gen", extra: <<~XML)
          <additionalPrerequisites>
            <ContractPrerequisite_Locality localityAvailable="#{locality}" />
            <ContractPrerequisite_Location locationAvailable="#{place}" />
          </additionalPrerequisites>
        XML

        assert_equal [locality_place, place].sort, @parser.missions.sole[:offered_location_refs]
      end

      test "#missions fills the placeholders a contract states, layered template, handler, contract" do
        template_ref = "5d1e0c3a-0000-4000-8000-0000000000f1"
        translate(
          "Haul_Title" => "~mission(CargoGradeToken) Haul to ~mission(Destination|Address)",
          "Haul_Desc" => "Use a ~mission(MissionMaxSCUSize) elevator in ~mission(System), ~mission(ReputationRank).",
          "Grade_Small" => "Small", "Grade_Large" => "Large", "Elevator_4" => "4 SCU", "Elevator_32" => "32 SCU",
          "Stanton" => "Stanton System", "Rank_1" => "Member"
        )
        write("contracts/contracttemplates/haul", "ContractTemplate", template_ref, <<~XML)
          <contractProperties>
            #{text_property("CargoGradeToken", "@Grade_Small")}
            #{text_property("MissionMaxSCUSize", "@Elevator_4")}
            #{text_property("System", "@Stanton")}
            #{text_property("ReputationRank", "@LOC_UNINITIALIZED")}
          </contractProperties>
        XML
        generator("gen", title: "@Haul_Title", description: "@Haul_Desc", template: template_ref,
          handler_extra: "<contractParams><propertyOverrides>#{text_property("MissionMaxSCUSize", "@Elevator_32")}#{text_property("ReputationRank", "@Rank_1")}</propertyOverrides></contractParams>",
          properties: text_property("CargoGradeToken", "@Grade_Large"))

        values = @parser.missions.sole[:placeholder_values]

        assert_equal({"CargoGradeToken" => "Large", "MissionMaxSCUSize" => "32 SCU", "System" => "Stanton System",
          "ReputationRank" => "Member"}, values)
      end

      test "#missions fills a placeholder a value carries, and lists the options a contract offers" do
        translate(
          "Fuel_Desc" => "Bring ~mission(FuelType) to ~mission(Ship).",
          "Fuel_Hydrogen" => "<EM4>~mission(HydrogenFuel) SCU of Hydrogen</EM4>",
          "Fuel_Quantum" => "Quantum Fuel"
        )
        generator("gen", description: "@Fuel_Desc",
          properties: text_property("FuelType", "@Fuel_Hydrogen", "@Fuel_Quantum") + integer_property("HydrogenFuel", 6))

        assert_equal({"FuelType" => "<EM4>~mission(HydrogenFuel) SCU of Hydrogen</EM4> / Quantum Fuel", "HydrogenFuel" => "6"},
          @parser.missions.sole[:placeholder_values])
      end

      test "#missions leaves a number the game rolls or works out as a placeholder" do
        translate("Code_Desc" => "Code ~mission(ApprovalCode), ~mission(QTFuel) SCU, ~mission(ScripAmount) scrip.")
        generator("gen", description: "@Code_Desc",
          properties: integer_property("ApprovalCode", 1000, variation: 8000) + integer_property("QTFuel", 0) +
            integer_property("ScripAmount", 25))

        assert_equal({"ScripAmount" => "25"}, @parser.missions.sole[:placeholder_values])
      end

      test "#missions names a mission item, unless it could be more than three" do
        refs = (1..4).map { |index| "5d1e0c3a-0000-4000-8000-0000000000d#{index}" }
        translate("Item_Desc" => "Find ~mission(Item1) and ~mission(Item2).", "Item_Medical" => "Medical Supplies")
        refs.each { |ref| named_entity("entities/carryables/#{ref}", ref:, name: "@Item_Medical") }
        generator("gen", description: "@Item_Desc",
          properties: item_property("Item1", refs.first(1)) + item_property("Item2", refs))

        mission = @parser.missions.sole

        assert_equal({"Item1" => "Medical Supplies"}, mission[:placeholder_values])
        assert_not_includes mission, :placeholder_items
      end

      test "#missions carries no placeholder values for a contract that states none" do
        translate("Plain_Desc" => "Go to ~mission(Location|Address).")
        generator("gen", description: "@Plain_Desc")

        assert_not_includes @parser.missions.sole, :placeholder_values
      end

      # `@LOC_UNINITIALIZED` is a real entry in the localisation file rather than
      # a missing key, so it resolves happily and would ship as a mission name.
      test "#missions leaves an uninitialized title blank rather than shipping the marker" do
        translate("LOC_UNINITIALIZED" => "<= UNINITIALIZED =>")
        generator("gen", title: "@LOC_UNINITIALIZED")

        assert_not_includes @parser.missions.sole, :title
      end

      test "#all writes both catalogues" do
        pool("bp_missionreward_example")
        generator("gen")

        @parser.all

        assert_equal 1, Dir.glob("#{@base_folder}/parsed/test/blueprint_pools/*.json").size
        assert_equal 1, Dir.glob("#{@base_folder}/parsed/test/game_missions/*.json").size
      end

      test "#all clears the missions folder when the generator tree is gone" do
        generator("gen")
        @parser.all

        assert_equal 1, Dir.glob("#{@base_folder}/parsed/test/game_missions/*.json").size

        FileUtils.rm_rf("#{@raw_path}/#{RECORDS_PATH}/contracts")

        ::ScData::Parser::ContractsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        ).all

        assert_empty Dir.glob("#{@base_folder}/parsed/test/game_missions/*.json")
      end

      # `save_items` returns before it clears, so a blank run would otherwise
      # leave the previous catalogue on disk -- and stale pools clear the floor
      # check and load as the current build's sources.
      test "#all clears the folder when the crafting tree is gone" do
        pool("bp_missionreward_example")
        @parser.all

        assert_equal 1, Dir.glob("#{@base_folder}/parsed/test/blueprint_pools/*.json").size

        FileUtils.rm_rf("#{@raw_path}/#{RECORDS_PATH}/crafting")

        ::ScData::Parser::ContractsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        ).all

        assert_empty Dir.glob("#{@base_folder}/parsed/test/blueprint_pools/*.json")
      end

      private def translate(entries)
        @parser.translations = entries
      end

      private def pool(key, group: "blueprintmissionpools", ref: POOL_REF, blueprint: BLUEPRINT_REF)
        write("crafting/blueprintrewards/#{group}/#{key}", "BlueprintPoolRecord", ref, <<~XML)
          <blueprintRewards>
            <BlueprintReward weight="1" blueprintRecord="#{blueprint}" />
          </blueprintRewards>
        XML
      end

      private def generator(key, handler: "ContractGeneratorHandler_Career", contract_kind: "CareerContract",
        org_ref: ORG_REF, min_standing: RANK0_REF, max_standing: RANK6_REF, pool_ref: POOL_REF,
        sibling_org: nil, second_org: nil, container: "contracts", contract_ids: [CONTRACT_ID],
        debug_name: nil, title: TITLE_KEY, description: nil, released: true, difficulty: nil, results: nil,
        properties: nil, extra: nil, results_attributes: "", handler_extra: nil, template: nil)
        siblings = [sibling_org, second_org].compact.map.with_index do |ref, index|
          %(<ContractGeneratorHandler_Career debugName="Sibling#{index}" factionReputation="#{ref}" />)
        end

        listed = contract_ids.map do |id|
          contract(contract_kind, id:, debug_name: debug_name || "#{key}_VeryEasy", min_standing:,
            max_standing:, pool_ref:, title:, description:, released:, difficulty:, results:, properties:,
            extra:, results_attributes:, template:)
        end

        write("contracts/contractgenerator/guild/#{key}", "ContractGenerator", "00000000-0000-0000-0000-0000000000aa", <<~XML)
          <generators>
            <#{handler} debugName="#{key}"#{%( factionReputation="#{org_ref}") if org_ref}>
              #{handler_extra}
              <#{container}>
                #{listed.join}
              </#{container}>
            </#{handler}>
            #{siblings.join}
          </generators>
        XML
      end

      private def contract(kind, id:, debug_name:, min_standing:, max_standing:, pool_ref:,
        title:, description:, released:, difficulty:, results:, properties:, extra:, results_attributes:,
        template: nil)
        params = [%(<ContractStringParam param="Title" value="#{title}" />)]
        params << %(<ContractStringParam param="Description" value="#{description}" />) if description

        <<~XML
          <#{kind} id="#{id}" debugName="#{debug_name}" notForRelease="#{released ? 0 : 1}"
            minStanding="#{min_standing}" maxStanding="#{max_standing}"#{%( template="#{template}") if template}>
            <paramOverrides>
              <stringParamOverrides>
                #{params.join}
              </stringParamOverrides>
              #{"<propertyOverrides>#{properties}</propertyOverrides>" if properties}
            </paramOverrides>
            #{extra}
            <contractResults #{results_attributes}>
              <contractResults>
                <contractResults>
                  <BlueprintRewards chance="1" blueprintPool="#{pool_ref}" />
                  #{results}
                </contractResults>
                #{difficulty_xml(difficulty)}
              </contractResults>
            </contractResults>
          </#{kind}>
        XML
      end

      private def difficulty_xml(bands)
        return "" if bands.blank?

        listed = bands.map { |name, value| %(#{name}="#{value}") }.join(" ")

        %(<difficulty><ContractDifficulty difficultyProfile="#{PROFILE_REF}" #{listed} /></difficulty>)
      end

      private def difficulty_profile(key, ref: PROFILE_REF)
        write("contracts/contractdifficultyprofiles/#{key}", "ContractDifficultyProfile", ref, "")
      end

      private def reputation_reward(key, ref:, amount:)
        write("reputation/rewards/missionrewards_reputation/#{key}", "SReputationRewardAmount", ref, "",
          reputationAmount: amount)
      end

      private def scenario(faction_ref:, min_points:, pool_ref: POOL_REF)
        write_at("contracts/contractscenarios/rox_scenarioprogress", "ScenarioProgress", "00000000-0000-0000-0000-0000000000bb", <<~XML)
          <factionRewardTiers>
            <SScenarioProgressRewardsTiers faction="#{faction_ref}">
              <tierProgressions>
                <STierProgressions>
                  <tierRewards>
                    <STierReward minPoints="#{min_points}">
                      <blueprintPool>
                        <Reference value="#{pool_ref}" />
                      </blueprintPool>
                    </STierReward>
                  </tierRewards>
                </STierProgressions>
              </tierProgressions>
            </SScenarioProgressRewardsTiers>
          </factionRewardTiers>
        XML
      end

      private def faction_reputation(key, ref:, display_name:, lawful: nil)
        body = if lawful.nil?
          ""
        else
          <<~XML
            <propertiesBB>
              <SReputationContextBBPropertyParams name="entityDescription">
                <dynamicProperty>
                  <SBBDynamicPropertyLocString value="@LOC_PLACEHOLDER" />
                </dynamicProperty>
              </SReputationContextBBPropertyParams>
              <SReputationContextBBPropertyParams name="entityLawful">
                <dynamicProperty>
                  <SBBDynamicPropertyBool value="#{lawful ? 1 : 0}" />
                </dynamicProperty>
              </SReputationContextBBPropertyParams>
            </propertiesBB>
          XML
        end

        write("factions/factionreputation/#{key}", "FactionReputation", ref, body, displayName: display_name)
      end

      private def faction(key, ref:, reputation_ref:)
        write("factions/#{key}", "Faction", ref, "", name: "@LOC_UNINITIALIZED", factionReputationRef: reputation_ref)
      end

      private def standing(key, ref:, display_name:, name: nil)
        write("reputation/standings/scope/#{key}", "SReputationStandingParams", ref, "",
          displayName: display_name, **(name ? {name:} : {}))
      end

      private def hand_in_property(orders)
        <<~XML
          <MissionProperty missionVariableName="HaulingOverride">
            <value>
              <MissionPropertyValue_HaulingOrders>
                <haulingOrderContent>
                  #{orders}
                </haulingOrderContent>
              </MissionPropertyValue_HaulingOrders>
            </value>
          </MissionProperty>
        XML
      end

      private def text_property(token, *text_ids)
        options = text_ids.map { |id| %(<MissionPropertyValueOption_StringHash textId="#{id}" weighting="1" />) }

        <<~XML
          <MissionProperty extendedTextToken="#{token}">
            <value><MissionPropertyValue_StringHash><options>#{options.join}</options></MissionPropertyValue_StringHash></value>
          </MissionProperty>
        XML
      end

      private def integer_property(token, value, variation: 0)
        <<~XML
          <MissionProperty missionVariableName="#{token}_BP" extendedTextToken="#{token}">
            <value><MissionPropertyValue_Integer><options>
              <MissionPropertyValueOption_Integer textId="@LOC_UNINITIALIZED" weighting="1" value="#{value}" variation="#{variation}" />
            </options></MissionPropertyValue_Integer></value>
          </MissionProperty>
        XML
      end

      private def item_property(token, refs)
        references = refs.map { |ref| %(<Reference value="#{ref}" />) }

        <<~XML
          <MissionProperty missionVariableName="#{token}" extendedTextToken="#{token}">
            <value><MissionPropertyValue_MissionItem minItemsToFind="1" maxItemsToFind="1"><matchConditions>
              <DataSetMatchCondition_SpecificItemsDef><items>#{references.join}</items></DataSetMatchCondition_SpecificItemsDef>
            </matchConditions></MissionPropertyValue_MissionItem></value>
          </MissionProperty>
        XML
      end

      private def named_entity(path, ref:, name:)
        write(path, "EntityClassDefinition", ref, <<~XML)
          <Components>
            <SAttachableComponentParams>
              <AttachDef>
                <Localization Name="#{name}" />
              </AttachDef>
            </SAttachableComponentParams>
          </Components>
        XML
      end

      private def resource_types(records)
        target = "#{@raw_path}/#{RECORDS_PATH}/resourcetypedatabase/resourcetypedatabase.records.xml"

        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, "<ResourceTypeDatabase>#{records}</ResourceTypeDatabase>")
      end

      private def write(path, type, ref, body, **attributes)
        write_at(path, type, ref, body, **attributes)
      end

      private def write_at(path, type, ref, body, **attributes)
        target = "#{@raw_path}/#{RECORDS_PATH}/#{path}.xml"
        listed = attributes.map { |name, value| %(#{name}="#{value}") }.join(" ")

        FileUtils.mkdir_p(File.dirname(target))

        File.write(target, <<~XML)
          <#{type}.#{File.basename(path)} #{listed} __type="#{type}" __ref="#{ref}"
            __path="libs/foundry/records/#{path}.xml">
            #{body}
          </#{type}.#{File.basename(path)}>
        XML
      end
    end
  end
end
