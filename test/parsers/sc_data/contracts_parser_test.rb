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
        sibling_org: nil, second_org: nil)
        siblings = [sibling_org, second_org].compact.map.with_index do |ref, index|
          %(<ContractGeneratorHandler_Career debugName="Sibling#{index}" factionReputation="#{ref}" />)
        end

        write("contracts/contractgenerator/guild/#{key}", "ContractGenerator", "00000000-0000-0000-0000-0000000000aa", <<~XML)
          <generators>
            <#{handler} debugName="#{key}"#{%( factionReputation="#{org_ref}") if org_ref}>
              <contracts>
                <#{contract_kind} debugName="#{key}_VeryEasy" minStanding="#{min_standing}" maxStanding="#{max_standing}">
                  <paramOverrides>
                    <stringParamOverrides>
                      <ContractStringParam param="Title" value="@Foxwell_ShipAmbush_VE_title_001" />
                    </stringParamOverrides>
                  </paramOverrides>
                  <contractResults>
                    <contractResults>
                      <contractResults>
                        <BlueprintRewards chance="1" blueprintPool="#{pool_ref}" />
                      </contractResults>
                    </contractResults>
                  </contractResults>
                </#{contract_kind}>
              </contracts>
            </#{handler}>
            #{siblings.join}
          </generators>
        XML
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

      private def faction_reputation(key, ref:, display_name:)
        write("factions/factionreputation/#{key}", "FactionReputation", ref, "", displayName: display_name)
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
