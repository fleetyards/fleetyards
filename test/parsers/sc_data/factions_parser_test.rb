# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ScData
  module Parser
    class FactionsParserTest < ActiveSupport::TestCase
      RECORDS_PATH = "Data/Libs/Foundry/Records"

      FACTION_REF = "016c2950-0292-468c-a408-a5283b52f158"
      CONTEXT_REF = "21c61135-e8ee-459c-8f61-4550b8c02c58"
      STANDING_SCOPE = "a8f635c5-0000-4000-8000-000000000001"
      SECURITY_SCOPE = "a8f635c5-0000-4000-8000-000000000002"
      SECURITY_GUILD_SCOPE = "a8f635c5-0000-4000-8000-000000000003"
      AFFINITY_SCOPE = "a8f635c5-0000-4000-8000-000000000004"
      UNNAMED_SCOPE = "a8f635c5-0000-4000-8000-000000000005"
      LOW_REF = "b8f635c5-0000-4000-8000-000000000001"
      HIGH_REF = "b8f635c5-0000-4000-8000-000000000002"
      PLACEHOLDER_REF = "b8f635c5-0000-4000-8000-000000000003"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", <<~INI)
          Foxwell_RepUI_Name=Foxwell Enforcement
          Foxwell_RepUI_Description=Private security.
          Foxwell_RepUI_Area=Stanton
          Rep_Standing=Standing
          Rep_Security=Security
          Rep_Affinity=Affinity
          Rank_Low=Neutral
          Rank_High=Elite Contractor
          Rank_Placeholder=<= PLACEHOLDER =>
        INI

        standing("low", ref: LOW_REF, display_name: "@Rank_Low", min: 0)
        standing("high", ref: HIGH_REF, display_name: "@Rank_High", min: 95_250)
        standing("placeholder", ref: PLACEHOLDER_REF, display_name: "@Rank_Placeholder", min: 500)

        @parser = ::ScData::Parser::FactionsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "#factions reads what the export states about a faction" do
        faction(context: nil)

        parsed = @parser.factions.sole

        assert_equal "factionreputation_lawful_foxwell", parsed[:sc_key]
        assert_equal FACTION_REF, parsed[:sc_ref]
        assert_equal "Foxwell Enforcement", parsed[:name]
        assert_equal "Private security.", parsed[:description]
        assert_equal "Stanton", parsed[:area]
        assert parsed[:lawful]
      end

      test "#factions skips a stub the export gives no name" do
        faction(context: nil, display_name: "@Missing_Key")

        assert_empty @parser.factions
      end

      test "#factions reads a ladder's ranks lowest first, dropping placeholder names" do
        scope("reputationscope_standing", ref: STANDING_SCOPE, display_name: "@Rep_Standing",
          ranks: [HIGH_REF, PLACEHOLDER_REF, LOW_REF], ceiling: 95_250)
        context(primary: STANDING_SCOPE)
        faction

        ladder = @parser.factions.sole[:ladders].sole

        assert_equal "reputationscope_standing", ladder[:key]
        assert_equal "Standing", ladder[:name]
        assert_equal 95_250, ladder[:ceiling]
        assert_equal [{name: "Neutral", min_reputation: 0}, {name: "Elite Contractor", min_reputation: 95_250}], ladder[:ranks]
      end

      test "#factions adds the scopes its awards feed to the ones its context lists, busiest first" do
        scope("reputationscope_standing", ref: STANDING_SCOPE, display_name: "@Rep_Standing", ranks: [LOW_REF])
        scope("reputationscope_security", ref: SECURITY_SCOPE, display_name: "@Rep_Security", ranks: [HIGH_REF])
        context(primary: SECURITY_SCOPE)
        faction
        generator(scopes: [STANDING_SCOPE, STANDING_SCOPE])

        assert_equal %w[Standing Security], @parser.factions.sole[:ladders].pluck(:name)
      end

      test "#factions puts affinity last even when awards feed it most" do
        scope("reputationscope_affinity", ref: AFFINITY_SCOPE, display_name: "@Rep_Affinity", ranks: [LOW_REF])
        scope("reputationscope_standing", ref: STANDING_SCOPE, display_name: "@Rep_Standing", ranks: [HIGH_REF])
        faction(context: nil)
        generator(scopes: [AFFINITY_SCOPE, AFFINITY_SCOPE, STANDING_SCOPE])

        assert_equal %w[Standing Affinity], @parser.factions.sole[:ladders].pluck(:name)
      end

      test "#factions keeps one of two ladders a reader could not tell apart, the one awards feed" do
        scope("reputationscope_security", ref: SECURITY_SCOPE, display_name: "@Rep_Security", ranks: [LOW_REF])
        scope("reputationscope_security_guild", ref: SECURITY_GUILD_SCOPE, display_name: "@Rep_Security", ranks: [LOW_REF])
        context(primary: SECURITY_SCOPE, listed: [SECURITY_GUILD_SCOPE])
        faction
        generator(scopes: [SECURITY_GUILD_SCOPE])

        assert_equal ["reputationscope_security_guild"], @parser.factions.sole[:ladders].pluck(:key)
      end

      test "#factions drops a ladder with no resolved name or no named rank" do
        scope("reputationscope_unnamed", ref: UNNAMED_SCOPE, display_name: "@Missing_Key", ranks: [LOW_REF])
        scope("reputationscope_standing", ref: STANDING_SCOPE, display_name: "@Rep_Standing", ranks: [PLACEHOLDER_REF])
        context(primary: UNNAMED_SCOPE, listed: [STANDING_SCOPE])
        faction

        assert_empty @parser.factions.sole[:ladders]
      end

      test "#factions does not count an award again for a contract slot's inlined copy" do
        write("contracts/contractgenerator/gen", "ContractGenerator", "00000000-0000-0000-0000-0000000000aa", <<~XML)
          <ContractResult_LegacyReputation>
            <contractResultReputationAmounts factionReputation="#{FACTION_REF}" reputationScope="#{STANDING_SCOPE}" />
          </ContractResult_LegacyReputation>
          <otherLocationFilter>
            <contractResultReputationAmounts factionReputation="#{FACTION_REF}" reputationScope="#{SECURITY_SCOPE}" />
          </otherLocationFilter>
        XML

        assert_equal({STANDING_SCOPE => 1}, @parser.send(:awarded_scopes)[FACTION_REF])
      end

      test "#all leaves the manufacturer logos sharing its folder in place" do
        logos = "#{@base_folder}/parsed/test/icons/ui/sharedassets/manufacturerlogos"
        FileUtils.mkdir_p(logos)
        File.write("#{logos}/behring_256.png", "logo")

        raw_logos = "#{@raw_path}/Data/ui/sharedassets/manufacturerlogos"
        FileUtils.mkdir_p(raw_logos)
        File.write("#{raw_logos}/rep_foxwell.png", "logo")

        faction(context: nil, logo: "UI/SharedAssets/ManufacturerLogos/rep_foxwell.tif")

        @parser.all

        assert_path_exists "#{logos}/behring_256.png"
        assert_path_exists "#{@base_folder}/parsed/test/factions/factionreputation_lawful_foxwell.json"
      end

      private def faction(context: CONTEXT_REF, display_name: "@Foxwell_RepUI_Name", logo: nil)
        write("factions/factionreputation/factionreputation_lawful_foxwell", "FactionReputation", FACTION_REF, <<~XML,
          <propertiesBB>
            #{text_entry("entityDescription", "@Foxwell_RepUI_Description")}
            #{text_entry("entityArea", "@Foxwell_RepUI_Area")}
            <SReputationContextBBPropertyParams name="entityLawful">
              <dynamicProperty><SBBDynamicPropertyBool value="1" /></dynamicProperty>
            </SReputationContextBBPropertyParams>
          </propertiesBB>
        XML
          displayName: display_name, reputationContextPropertiesUI: context, logo:)
      end

      private def text_entry(name, value)
        <<~XML
          <SReputationContextBBPropertyParams name="#{name}">
            <dynamicProperty><SBBDynamicPropertyLocString value="#{value}" /></dynamicProperty>
          </SReputationContextBBPropertyParams>
        XML
      end

      private def context(primary:, listed: [])
        entries = listed.map { |ref| %(<SReputationScopeContextUI scope="#{ref}" />) }.join

        write("reputation/contexts/context", "SReputationContextUI", CONTEXT_REF, <<~XML)
          <primaryScopeContext scope="#{primary}" />
          <scopeContextList>#{entries}</scopeContextList>
        XML
      end

      private def scope(key, ref:, display_name:, ranks:, ceiling: 1000)
        references = ranks.map { |rank| %(<Reference value="#{rank}" />) }.join

        write("reputation/scopes/#{key}", "SReputationScopeParams", ref, <<~XML, displayName: display_name)
          <standingMap reputationCeiling="#{ceiling}" initialReputation="0">
            <standings>#{references}</standings>
          </standingMap>
        XML
      end

      private def standing(key, ref:, display_name:, min:)
        write("reputation/standings/scope/#{key}", "SReputationStandingParams", ref, "",
          displayName: display_name, minReputation: min)
      end

      private def generator(scopes:)
        amounts = scopes.map { |scope|
          %(<contractResultReputationAmounts factionReputation="#{FACTION_REF}" reputationScope="#{scope}" />)
        }.join

        write("contracts/contractgenerator/gen", "ContractGenerator", "00000000-0000-0000-0000-0000000000aa", <<~XML)
          <ContractResult_LegacyReputation>#{amounts}</ContractResult_LegacyReputation>
        XML
      end

      private def write(path, type, ref, body, **attributes)
        file = "#{@raw_path}/#{RECORDS_PATH}/#{path}.xml"
        FileUtils.mkdir_p(File.dirname(file))

        element = "#{type}.#{File.basename(path)}"
        stated = attributes.compact.map { |name, value| %(#{name}="#{value}") }.join(" ")

        File.write(file, %(<#{element} #{stated} __type="#{type}" __ref="#{ref}">#{body}</#{element}>))
      end
    end
  end
end
