# frozen_string_literal: true

require "test_helper"
require "tmpdir"

# `parse_equipment` returns early on a blank name, so a key the export declares
# in a spelling `translate` cannot match does not load nameless -- it does not
# load at all. 84 records were missing from the catalogue for that reason.
module ScData
  module Parser
    class EquipmentParserTest < ActiveSupport::TestCase
      SOURCE_PATH = "entities/scitem/characters/human/clothing"

      setup do
        @base_folder = Dir.mktmpdir
        @raw_path = "#{@base_folder}/raw/1.0.0"

        FileUtils.mkdir_p("#{@raw_path}/Data/Localization/english")
        File.write("#{@raw_path}/Data/Localization/english/global.ini", "")

        write_equipment("hdh_boots_01_01_13", name: "@item_Name_hdh_boots_01_01_13")

        @parser = ::ScData::Parser::EquipmentParser.new(
          base_folder: @base_folder, sc_version: "1.0.0", sc_environment: "test"
        )
      end

      teardown do
        FileUtils.remove_entry(@base_folder)
      end

      test "loads a record whose name the export declares with a plural marker" do
        @parser.translations = {"item_Name_hdh_boots_01_01_13,P" => "Novian \"Nighthunter\" Boots"}

        assert_equal "Novian \"Nighthunter\" Boots", parsed.fetch("hdh_boots_01_01_13")["name"]
      end

      test "loads a record whose name the export declares in another case" do
        @parser.translations = {"item_name_hdh_boots_01_01_13" => "P4-AR \"Star Kitten\" Rifle"}

        assert_equal "P4-AR \"Star Kitten\" Rifle", parsed.fetch("hdh_boots_01_01_13")["name"]
      end

      test "leaves out a record the export has not named at all" do
        @parser.translations = {}

        assert_empty parsed
      end

      # 25 of the records the index unlocks are named "PH - hdh_boots_01_01_13"
      # or "PLACEHOLDER - SPV Jacket". They are better left where they are.
      test "leaves out a record whose name the export marks as a placeholder" do
        @parser.translations = {"item_Name_hdh_boots_01_01_13,P" => "PH - hdh_boots_01_01_13"}

        assert_empty parsed
      end

      # The tints and colourways among the newly named records still have to
      # hide, and `VARIANT_SUFFIX` decides that from the key rather than from
      # the name -- so a record arriving with a name for the first time does not
      # arrive visible for the first time.
      test "hides a colourway the export declares with a plural marker" do
        write_equipment("mrai_flightsuit_01_07_tint02", name: "@item_Name_mrai_flightsuit_01_07_tint02")

        @parser.translations = {
          "item_Name_hdh_boots_01_01_13,P" => "Novian \"Nighthunter\" Boots",
          "item_Name_mrai_flightsuit_01_07_tint02,P" => "Neutrino Racing Flight Suit WhiteHot"
        }

        assert parsed.fetch("mrai_flightsuit_01_07_tint02")["hidden"]
        assert_not parsed.fetch("hdh_boots_01_01_13")["hidden"]
      end

      # Memoized: a second `all` on the same parser writes over a folder
      # `clear_once` has already swept, which the parser reports as a duplicate.
      private def parsed
        @parsed ||= begin
          @parser.all

          Dir.glob("#{@base_folder}/parsed/test/equipment/*.json").to_h do |file|
            [File.basename(file, ".json"), JSON.parse(File.read(file))]
          end
        end
      end

      private def write_equipment(key, name:)
        folder = "#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/#{SOURCE_PATH}"

        FileUtils.mkdir_p(folder)

        File.write("#{folder}/#{key}.xml", <<~XML)
          <EntityClassDefinition.#{key} __ref="00000000-0000-0000-0000-00000000beef">
            <Components>
              <SAttachableComponentParams>
                <AttachDef Type="Char_Clothing_Feet" SubType="UNDEFINED" Size="1" Grade="1" Tags="#{key}">
                  <Localization Name="#{name}" ShortName="@LOC_EMPTY" Description="@LOC_EMPTY" />
                </AttachDef>
              </SAttachableComponentParams>
            </Components>
          </EntityClassDefinition.#{key}>
        XML
      end
    end
  end
end
