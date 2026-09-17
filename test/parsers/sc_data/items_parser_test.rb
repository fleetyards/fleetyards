# frozen_string_literal: true

require "test_helper"
require "tmpdir"

# An item keeps its row whatever its name resolves to, so a key the export
# declares in a spelling `translate` cannot match loads the record nameless --
# 234 ship items, the Redeemer's and the Polaris' armour among them.
module ScData
  module Parser
    class ItemsParserTest < ActiveSupport::TestCase
      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        write_item(
          "armr_aegs_redeemer",
          name: "@item_NameARMR_AEGS_Redeemer",
          short_name: "@item_shortARMR_AEGS_Redeemer",
          description: "@item_DescARMR_AEGS_Redeemer"
        )

        @parser = ::ScData::Parser::ItemsParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "carries a name the export declares with a plural marker" do
        @parser.translations = {"item_NameARMR_AEGS_Redeemer,P" => "Aegis Redeemer Ship Armor"}

        assert_equal "Aegis Redeemer Ship Armor", parsed["name"]
      end

      test "carries a name the export declares in another case" do
        @parser.translations = {"item_namearmr_aegs_redeemer" => "Aegis Redeemer Ship Armor"}

        assert_equal "Aegis Redeemer Ship Armor", parsed["name"]
      end

      test "carries a short name the export declares with a plural marker" do
        @parser.translations = {"item_shortARMR_AEGS_Redeemer,P" => "Redeemer Armor"}

        assert_equal "Redeemer Armor", parsed["short_name"]
      end

      test "keeps the row of an item the export has not named" do
        @parser.translations = {}

        assert_nil parsed["name"]
        assert_equal "armr_aegs_redeemer", parsed["key"]
      end

      # The description is left on `translate` on purpose: `describe` reads the
      # prose it returns, and the index would hand back the same paragraph with
      # its newlines already unescaped -- a different string for all 3019
      # descriptions the export writes with one.
      test "leaves the description as the export writes it" do
        @parser.translations = {
          "item_DescARMR_AEGS_Redeemer" => 'Item Type: Armor\nManufacturer: Aegis Dynamics'
        }

        assert_equal 'Item Type: Armor\nManufacturer: Aegis Dynamics', parsed["description"]
      end

      private def parsed
        @parsed ||= begin
          @parser.all

          JSON.parse(File.read("#{@base_folder}/parsed/test/items/armr_aegs_redeemer.json"))
        end
      end

      # Any item in the tree, for a test that writes its own rather than reading
      # the one the setup always creates.
      private def parsed_item(key)
        @parser.all

        JSON.parse(File.read("#{@base_folder}/parsed/test/items/#{key}.json"))
      end

      # `normalize_tags` begins with `to_s`, so handing it the already-split
      # array turned the list into its own inspect output: every component in
      # the tree stored the single string `["$flightReady"]` rather than the tag
      # inside it. `required_tags` was always passed the raw value, which is why
      # only one of the pair was wrong.
      test "stores each tag on its own, rather than the array's inspect output" do
        write_item(
          "armr_tagged",
          name: "@item_NameTagged",
          tags: "$flightReady $drak_ironclad",
          required_tags: "$drak_ironclad"
        )

        item = parsed_item("armr_tagged")

        assert_equal %w[flightReady drak_ironclad], item["tags"]
        assert_equal %w[drak_ironclad], item["required_tags"]
      end

      test "carries no tags rather than an empty string for an item with none" do
        write_item("armr_untagged", name: "@item_NameUntagged", tags: " ")

        assert_empty parsed_item("armr_untagged")["tags"]
      end

      private def write_item(key, name:, short_name: "@LOC_EMPTY", description: "@LOC_EMPTY", tags: nil, required_tags: nil)
        folder = "#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/scitem/ships/armor"

        FileUtils.mkdir_p(folder)

        File.write("#{folder}/#{key}.xml", <<~XML)
          <EntityClassDefinition.#{key} __ref="00000000-0000-0000-0000-00000000beef">
            <Components>
              <SAttachableComponentParams>
                <AttachDef Type="Armor" SubType="UNDEFINED" Size="1" Grade="1" Tags="#{tags || key}" RequiredTags="#{required_tags}">
                  <Localization Name="#{name}" ShortName="#{short_name}" Description="#{description}" />
                </AttachDef>
              </SAttachableComponentParams>
            </Components>
          </EntityClassDefinition.#{key}>
        XML
      end
    end
  end
end
