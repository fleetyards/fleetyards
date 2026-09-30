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

      test "reads no turn rate for an axis only a slaved joint turns" do
        write_item("slaved_only", name: "@item_Nameslaved_only", category: "turret", type: "Turret", sub_type: "GunTurret", components: <<~XML)
          <SCItemTurretParams>
            <movementList>
              <SCItemTurretJointMovementParams jointName="follower" slavedOnly="1">
                <yawAxis>
                  <SCItemTurretJointMovementAxisParams speed="200" />
                </yawAxis>
              </SCItemTurretJointMovementParams>
            </movementList>
          </SCItemTurretParams>
        XML

        assert_nil parsed_item("slaved_only")["type_data"]["yaw_speed"]
      end

      test "reads a mount's fixed angle limits per axis" do
        write_turret("gimbal_limits",
          yaw_limits: '<SCItemTurretStandardAngleLimitParams LowestAngle="-80" HighestAngle="80" />',
          pitch_limits: '<SCItemTurretStandardAngleLimitParams LowestAngle="-20" HighestAngle="20" />')

        type_data = parsed_item("gimbal_limits")["type_data"]

        assert_in_delta(-80.0, type_data["min_yaw"])
        assert_in_delta 80.0, type_data["max_yaw"]
        assert_in_delta(-20.0, type_data["min_pitch"])
        assert_in_delta 20.0, type_data["max_pitch"]
        assert_nil type_data["yaw_limits_vary"]
        assert_nil type_data["pitch_limits_vary"]
      end

      test "keeps the widest range of a limit that changes with rotation" do
        write_turret("bubble_limits", pitch_limits: <<~XML)
          <SCItemTurretCustomAngleLimitParams RelativeJointName="yaw_part">
            <AngleLimits>
              <SCItemTurretCustomAngleLimit TurretRotation="0" LowestAngle="-85" HighestAngle="0" />
              <SCItemTurretCustomAngleLimit TurretRotation="100" LowestAngle="-85" HighestAngle="-15" />
            </AngleLimits>
            <limitOverwrites>
              <SCItemTurretCustomAngleLimitTagOverwriteParams limiterTag="00000000-0000-0000-0000-000000000002">
                <AngleLimits>
                  <SCItemTurretCustomAngleLimit TurretRotation="0" LowestAngle="-89" HighestAngle="89" />
                </AngleLimits>
              </SCItemTurretCustomAngleLimitTagOverwriteParams>
            </limitOverwrites>
          </SCItemTurretCustomAngleLimitParams>
        XML

        type_data = parsed_item("bubble_limits")["type_data"]

        assert_in_delta(-85.0, type_data["min_pitch"])
        assert_in_delta 0.0, type_data["max_pitch"]
        assert type_data["pitch_limits_vary"]
      end

      test "never joins the ends of two rotations into a full turn" do
        write_turret("half_turns", yaw_limits: <<~XML)
          <SCItemTurretCustomAngleLimitParams RelativeJointName="pitch_part">
            <AngleLimits>
              <SCItemTurretCustomAngleLimit TurretRotation="0" LowestAngle="-180" HighestAngle="0" />
              <SCItemTurretCustomAngleLimit TurretRotation="100" LowestAngle="0" HighestAngle="150" />
            </AngleLimits>
          </SCItemTurretCustomAngleLimitParams>
        XML

        type_data = parsed_item("half_turns")["type_data"]

        assert_in_delta(-180.0, type_data["min_yaw"])
        assert_in_delta 0.0, type_data["max_yaw"]
        assert type_data["yaw_limits_vary"]
      end

      test "describes an axis two joints share by the wider one" do
        write_turret("cradle_yaw",
          yaw_limits: '<SCItemTurretStandardAngleLimitParams LowestAngle="-180" HighestAngle="180" />',
          extra_joints: <<~XML)
            <SCItemTurretJointMovementParams jointName="cradle_yaw" slavedOnly="0">
              <yawAxis>
                <SCItemTurretJointMovementAxisParams speed="40">
                  <angleLimits><SCItemTurretStandardAngleLimitParams LowestAngle="-75" HighestAngle="75" /></angleLimits>
                </SCItemTurretJointMovementAxisParams>
              </yawAxis>
            </SCItemTurretJointMovementParams>
          XML

        type_data = parsed_item("cradle_yaw")["type_data"]

        assert_in_delta(-180.0, type_data["min_yaw"])
        assert_in_delta 180.0, type_data["max_yaw"]
        assert_nil type_data["yaw_limits_vary"]
      end

      test "marks a point-defence turret by a tag written with its prefix" do
        write_turret("pdc_tagged", tags: "$flightReady $PDC")

        assert_equal "pds", parsed_item("pdc_tagged")["type_data"]["control"]
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

      test "reads a missile's lock cone, flight phases and fuse" do
        write_item("misl_probe", name: "@item_Namemisl_probe", category: "weapons", components: <<~XML)
          <SCItemMissileParams maxLifetime="15" armTime="1.5" explosionSafetyDistance="5">
            <targetingParams trackingSignalType="Infrared" trackingSignalMin="15" lockTime="0.5" lockingAngle="60"
              lockRangeMin="1700" lockRangeMax="10000" signalResilienceMin="1" signalResilienceMax="1.7" allowDumbFiring="1" />
            <GCSParams linearSpeed="1372" boostPhaseDuration="2" terminalPhaseEngagementTime="1"
              terminalPhaseEngagementAngle="45" fuelTankSize="30" />
            <explosionParams minRadius="3" maxRadius="5">
              <damage><DamageInfo DamagePhysical="650" /></damage>
            </explosionParams>
          </SCItemMissileParams>
        XML

        type_data = parsed_item("misl_probe")["type_data"]

        assert_in_delta 60.0, type_data["lock_angle"]
        assert_in_delta 1.7, type_data["signal_resilience_max"]
        assert type_data["dumbfire"]
        assert_in_delta 2.0, type_data["boost_phase_duration"]
        assert_in_delta 1.0, type_data["terminal_phase_time"]
        assert_in_delta 30.0, type_data["fuel_tank_size"]
        assert_in_delta 1.5, type_data["arm_time"]
        assert_in_delta 5.0, type_data["safety_distance"]
        assert_in_delta 3.0, type_data["blast_radius_min"]
        assert_in_delta 5.0, type_data["blast_radius_max"]
        assert_in_delta 20_580.0, type_data["range"]
      end

      test "reads a bomb's warhead, fuse and drop angle" do
        write_item("bomb_probe", name: "@item_Namebomb_probe", category: "weapons", components: <<~XML)
          <SCItemBombParams maxLifetime="300" armTime="3" explosionSafetyDistance="50" maximumDropAngleFromFlatFlight="90">
            <explosionParams minRadius="100" maxRadius="100">
              <damage><DamageInfo DamagePhysical="22346" DamageEnergy="24356" /></damage>
            </explosionParams>
          </SCItemBombParams>
        XML

        type_data = parsed_item("bomb_probe")["type_data"]

        assert_in_delta 22_346.0, type_data["damage_per_shot"]["physical"]
        assert_in_delta 24_356.0, type_data["damage_per_shot"]["energy"]
        assert_in_delta 90.0, type_data["max_drop_angle"]
        assert_in_delta 3.0, type_data["arm_time"]
        assert_in_delta 100.0, type_data["blast_radius_max"]
      end

      test "reads no warhead from an explosion whose damage is not a block" do
        write_item("bomb_blank", name: "@item_Namebomb_blank", category: "weapons", components: <<~XML)
          <SCItemBombParams armTime="3">
            <explosionParams minRadius="10" maxRadius="10"><damage>none</damage></explosionParams>
          </SCItemBombParams>
        XML

        type_data = parsed_item("bomb_blank")["type_data"]

        assert_nil type_data["damage_per_shot"]
        assert_in_delta 3.0, type_data["arm_time"]
      end

      test "reads a rack's launch delay and whether it ignites on the pylon" do
        write_item("mrck_probe", name: "@item_Namemrck_probe", category: "missile_racks", components: <<~XML)
          <SCItemMissileRackParams launchDelay="0.125" igniteOnPylon="0" />
        XML

        type_data = parsed_item("mrck_probe")["type_data"]

        assert_in_delta 0.125, type_data["launch_delay"]
        refute type_data["ignite_on_pylon"]
      end

      private def write_turret(key, yaw_speed: 50, pitch_speed: 50, type: "Turret", sub_type: "GunTurret", remote: false, tags: nil, extra_joints: "", yaw_limits: nil, pitch_limits: nil)
        remote_params = remote ? "<remoteTurret><SCItemTurretRemoteParams remoteCamera=\"00000000-0000-0000-0000-000000000001\" /></remoteTurret>" : ""

        write_item(key, name: "@item_Name#{key}", category: "turret", type:, sub_type:, tags:, components: <<~XML)
          <SCItemTurretParams rotationStyle="SingleAxis">
            <movementList>
              <SCItemTurretJointMovementParams jointName="yaw_part" slavedOnly="0">
                <yawAxis>
                  <SCItemTurretJointMovementAxisParams speed="#{yaw_speed}">
                    <angleLimits>#{yaw_limits}</angleLimits>
                  </SCItemTurretJointMovementAxisParams>
                </yawAxis>
              </SCItemTurretJointMovementParams>
              <SCItemTurretJointMovementParams jointName="pitch_part" slavedOnly="0">
                <pitchAxis>
                  <SCItemTurretJointMovementAxisParams speed="#{pitch_speed}">
                    <angleLimits>#{pitch_limits}</angleLimits>
                  </SCItemTurretJointMovementAxisParams>
                </pitchAxis>
              </SCItemTurretJointMovementParams>
              #{extra_joints}
            </movementList>
            #{remote_params}
          </SCItemTurretParams>
        XML
      end

      test "reads a gun's spread off its projectile launcher" do
        write_gun("scatter_spread", spread: '<spreadParams min="4" max="6" firstAttack="0.5" attack="0.45" decay="0.6" />')

        spread = parsed_item("scatter_spread")["type_data"]["spread"]

        assert_in_delta 4.0, spread["min"]
        assert_in_delta 6.0, spread["max"]
        assert_in_delta 0.5, spread["first_attack"]
        assert_in_delta 0.45, spread["attack"]
        assert_in_delta 0.6, spread["decay"]
      end

      test "carries no spread for a gun whose launcher declares none" do
        write_gun("no_spread")

        assert_nil parsed_item("no_spread")["type_data"]["spread"]
      end

      private def write_gun(key, spread: "")
        write_item(key, name: "@item_Name#{key}", category: "weapons", type: "WeaponGun", sub_type: "Gun", components: <<~XML)
          <SCItemWeaponComponentParams>
            <fireActions>
              <SWeaponActionFireSingleParams fireRate="750" heatPerShot="0">
                <launchParams>
                  <SProjectileLauncher ammoCost="1" pelletCount="1">
                    #{spread}
                  </SProjectileLauncher>
                </launchParams>
              </SWeaponActionFireSingleParams>
            </fireActions>
          </SCItemWeaponComponentParams>
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
