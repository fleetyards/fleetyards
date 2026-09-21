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

      # `Dir.glob` fixes no order between builds, so the second key cannot be
      # positional: a counter would swap the two contracts' history the first
      # time the walk came back in the other order.
      test "#missions disambiguates two contracts sharing a generator and a debug name" do
        generator("headhunters", debug_name: "Simple_Hit", contract_ids: [CONTRACT_ID, SECOND_CONTRACT_ID])

        keys = @parser.missions.pluck(:sc_key)

        assert_equal 2, keys.size
        assert_includes keys, "headhunters_simple_hit"
        assert_includes keys, "headhunters_simple_hit_#{SECOND_CONTRACT_ID.delete("-").first(8)}"
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

      # 2352 of the 2536 contracts award this and it is an empty element on
      # every one of them: the game computes the figure at run time and the
      # export states no table it could be computed from here.
      test "#missions states no payout for the calculated reward, which states none" do
        generator("gen", results: %(<ContractResult_CalculatedReward><missionResults><Bool value="1" /></missionResults></ContractResult_CalculatedReward>))

        assert_empty @parser.missions.sole[:rewards]
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
        debug_name: nil, title: TITLE_KEY, description: nil, released: true, difficulty: nil, results: nil)
        siblings = [sibling_org, second_org].compact.map.with_index do |ref, index|
          %(<ContractGeneratorHandler_Career debugName="Sibling#{index}" factionReputation="#{ref}" />)
        end

        listed = contract_ids.map do |id|
          contract(contract_kind, id:, debug_name: debug_name || "#{key}_VeryEasy", min_standing:,
            max_standing:, pool_ref:, title:, description:, released:, difficulty:, results:)
        end

        write("contracts/contractgenerator/guild/#{key}", "ContractGenerator", "00000000-0000-0000-0000-0000000000aa", <<~XML)
          <generators>
            <#{handler} debugName="#{key}"#{%( factionReputation="#{org_ref}") if org_ref}>
              <#{container}>
                #{listed.join}
              </#{container}>
            </#{handler}>
            #{siblings.join}
          </generators>
        XML
      end

      private def contract(kind, id:, debug_name:, min_standing:, max_standing:, pool_ref:,
        title:, description:, released:, difficulty:, results:)
        params = [%(<ContractStringParam param="Title" value="#{title}" />)]
        params << %(<ContractStringParam param="Description" value="#{description}" />) if description

        <<~XML
          <#{kind} id="#{id}" debugName="#{debug_name}" notForRelease="#{released ? 0 : 1}"
            minStanding="#{min_standing}" maxStanding="#{max_standing}">
            <paramOverrides>
              <stringParamOverrides>
                #{params.join}
              </stringParamOverrides>
            </paramOverrides>
            <contractResults>
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
