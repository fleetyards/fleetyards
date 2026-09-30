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

      test "keeps a livery whose colour is light" do
        write_item("paint_valkyrie_invictus_light_grey", name: "@item_NameValkyrie", category: "paints")

        assert_equal "paint_valkyrie_invictus_light_grey", parsed_item("paint_valkyrie_invictus_light_grey")["key"]
      end

      test "still drops a light fitted into a hull" do
        write_item("controller_light", name: "@item_NameLight", category: "controller")
        @parser.all

        assert_not File.exist?("#{@base_folder}/parsed/test/items/controller_light.json")
      end

      test "reads the armor's signature multipliers off its params" do
        write_item(
          "armr_signals",
          name: "@item_NameSignals",
          components: <<~XML
            <SCItemVehicleArmorParams signalInfrared="1.13" signalElectromagnetic="1.09" signalCrossSection="1.05" />
          XML
        )

        type_data = parsed_item("armr_signals")["type_data"]

        assert_in_delta 1.13, type_data["signal_infrared"]
        assert_in_delta 1.09, type_data["signal_electromagnetic"]
        assert_in_delta 1.05, type_data["signal_cross_section"]
      end

      test "reads a mount's turn rate per axis off its joints" do
        write_turret("mount_gimbal_s3", yaw_speed: 80, pitch_speed: 60)

        type_data = parsed_item("mount_gimbal_s3")["type_data"]

        assert_in_delta 80.0, type_data["yaw_speed"]
        assert_in_delta 60.0, type_data["pitch_speed"]
        assert_nil type_data["control"]
      end

      test "leaves a slaved joint out of the turn rate" do
        write_turret("slaved_turret", yaw_speed: 35, pitch_speed: 35, extra_joints: <<~XML)
          <SCItemTurretJointMovementParams jointName="follower" slavedOnly="1">
            <yawAxis>
              <SCItemTurretJointMovementAxisParams speed="200" />
            </yawAxis>
          </SCItemTurretJointMovementParams>
        XML

        assert_in_delta 35.0, parsed_item("slaved_turret")["type_data"]["yaw_speed"]
      end

      test "marks a turret aimed from a remote seat" do
        write_turret("remote_turret", remote: true)

        assert_equal "remote", parsed_item("remote_turret")["type_data"]["control"]
      end

      test "marks a turret with its own seat as manned" do
        write_turret("manned_turret", type: "TurretBase", sub_type: "MannedTurret")

        assert_equal "manned", parsed_item("manned_turret")["type_data"]["control"]
      end

      test "marks a point-defence turret as such, even though it is remote" do
        write_turret("pdc_turret", sub_type: "PDCTurret", remote: true)

        assert_equal "pds", parsed_item("pdc_turret")["type_data"]["control"]
      end

      private def write_turret(key, yaw_speed: 50, pitch_speed: 50, type: "Turret", sub_type: "GunTurret", remote: false, extra_joints: "")
        remote_params = remote ? "<remoteTurret><SCItemTurretRemoteParams remoteCamera=\"00000000-0000-0000-0000-000000000001\" /></remoteTurret>" : ""

        write_item(key, name: "@item_Name#{key}", category: "turret", type:, sub_type:, components: <<~XML)
          <SCItemTurretParams rotationStyle="SingleAxis">
            <movementList>
              <SCItemTurretJointMovementParams jointName="yaw_part" slavedOnly="0">
                <yawAxis>
                  <SCItemTurretJointMovementAxisParams speed="#{yaw_speed}" />
                </yawAxis>
              </SCItemTurretJointMovementParams>
              <SCItemTurretJointMovementParams jointName="pitch_part" slavedOnly="0">
                <pitchAxis>
                  <SCItemTurretJointMovementAxisParams speed="#{pitch_speed}" />
                </pitchAxis>
              </SCItemTurretJointMovementParams>
              #{extra_joints}
            </movementList>
            #{remote_params}
          </SCItemTurretParams>
        XML
      end

      private def write_item(key, name:, short_name: "@LOC_EMPTY", description: "@LOC_EMPTY", tags: nil, required_tags: nil, category: "armor", type: "Armor", sub_type: "UNDEFINED", components: "")
        folder = "#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/scitem/ships/#{category}"

        FileUtils.mkdir_p(folder)

        File.write("#{folder}/#{key}.xml", <<~XML)
          <EntityClassDefinition.#{key} __ref="00000000-0000-0000-0000-00000000beef">
            <Components>
              <SAttachableComponentParams>
                <AttachDef Type="#{type}" SubType="#{sub_type}" Size="1" Grade="1" Tags="#{tags || key}" RequiredTags="#{required_tags}">
                  <Localization Name="#{name}" ShortName="#{short_name}" Description="#{description}" />
                </AttachDef>
              </SAttachableComponentParams>
              #{components}
            </Components>
          </EntityClassDefinition.#{key}>
        XML
      end
    end
  end
end
