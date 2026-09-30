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

      test "reads a component's health, mass, repair and distortion into its durability" do
        write_item("qdrv_probe", name: "@item_Nameqdrv_probe", components: <<~XML)
          <SEntityPhysicsControllerParams>
            <PhysType>
              <SEntityRigidPhysicsControllerParams Mass="630" />
            </PhysType>
          </SEntityPhysicsControllerParams>
          <SHealthComponentParams Health="410">
            <DamageResistances>
              <DamageResistance>
                <PhysicalResistance Multiplier="0.85" />
                <ThermalResistance Multiplier="0.1" />
              </DamageResistance>
            </DamageResistances>
          </SHealthComponentParams>
          <ItemResourceComponentParams>
            <selfRepair maxRepairCount="1" timeToRepair="56" healthRatio="0.2" />
          </ItemResourceComponentParams>
          <SDistortionParams DecayDelay="3" DecayRate="233.3333" Maximum="3500" WarningRatio="0.75" RecoveryRatio="0" />
        XML

        durability = parsed_item("qdrv_probe")["durability"]

        assert_in_delta 410.0, durability["health"]
        assert_in_delta 630.0, durability["mass"]
        assert_equal(
          {"physical" => 0.85, "energy" => 1.0, "distortion" => 1.0, "thermal" => 0.1, "biochemical" => 1.0, "stun" => 1.0},
          durability["resistances"]
        )
        assert_equal({"time" => 56.0, "health_ratio" => 0.2, "max_repairs" => 1}, durability["self_repair"])
        assert_in_delta 3500.0, durability.dig("distortion", "maximum")
        assert_in_delta 0.75, durability.dig("distortion", "warning_ratio")
      end

      test "carries no distortion for an item the game never distorts" do
        write_item("armr_plain", name: "@item_Namearmr_plain", components: '<SHealthComponentParams Health="100" />')

        durability = parsed_item("armr_plain")["durability"]

        assert_equal({"health" => 100.0}, durability.except("resistances"))
        assert_equal [1.0], durability["resistances"].values.uniq
      end

      test "reads how long a quantum drive stays interdicted, in both modes" do
        write_item("qdrv_probe", name: "@item_Nameqdrv_probe", category: "quantumdrive", components: <<~XML)
          <SCItemQuantumDriveParams disconnectRange="34693">
            <params driveSpeed="263400000" engageSpeed="84000000" interdictionEffectTime="2.6" calibrationRate="1000" spoolUpTime="7.3" />
            <splineJumpParams driveSpeed="400000" stageOneAccelRate="250" stageTwoAccelRate="50000" interdictionEffectTime="5" spoolUpTime="6" cooldownTime="21.6" />
          </SCItemQuantumDriveParams>
        XML

        type_data = parsed_item("qdrv_probe")["type_data"]

        assert_in_delta 2.6, type_data["interdiction_effect_time"]
        assert_in_delta 5.0, type_data["spline_jump_params"]["interdiction_effect_time"]
        assert_in_delta 34_693.0, type_data["disconnect_range"]
      end

      test "reads a jump drive's tunnel flight from the record it points at" do
        tuning_folder = "#{@raw_path}/#{::ScData::Parser::BaseParser::FOUNDRY_PATH}/entities/scitem/ships/jumpdrive/jumpdriveflighttuning"
        FileUtils.mkdir_p(tuning_folder)
        File.write("#{tuning_folder}/jumpdriveflighttuning_s04.xml", <<~XML)
          <JumpDriveFlightParams.JumpDriveFlightTuning_S04 respoolTime="3" exitRecoverySpeed="200" __ref="00000000-0000-0000-0000-0000000f1172">
            <linear maxSpeed="1300" />
          </JumpDriveFlightParams.JumpDriveFlightTuning_S04>
        XML

        write_item("jdrv_probe", name: "@item_Namejdrv_probe", category: "jumpdrive", components: <<~XML)
          <SCItemJumpDriveParams alignmentRate="0.2" tuningRate="0.26" flightTuning="00000000-0000-0000-0000-0000000f1172" />
        XML

        type_data = parsed_item("jdrv_probe")["type_data"]

        assert_in_delta 200.0, type_data["exit_speed"]
        assert_in_delta 1300.0, type_data["max_tunnel_speed"]
        assert_in_delta 3.0, type_data["respool_time"]
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

      test "reads a mining laser's power, reach, module slots and modifiers" do
        write_item("mining_laser_probe", name: "@item_Namemining_laser_probe", category: "weapons", type: "WeaponMining", sub_type: "Gun", components: <<~XML)
          <SCItemWeaponComponentParams>
            <fireActions>
              <SWeaponActionFireBeamParams hitType="ElectricArc" fullDamageRange="60" zeroDamageRange="180" chargeUpTime="0.1" chargeDownTime="0.2">
                <damagePerSecond><DamageInfo DamagePhysical="0" DamageEnergy="2340" /></damagePerSecond>
              </SWeaponActionFireBeamParams>
              <SWeaponActionFireBeamParams hitType="Extraction" fullDamageRange="60" zeroDamageRange="180">
                <damagePerSecond><DamageInfo DamagePhysical="0" DamageEnergy="1850" /></damagePerSecond>
              </SWeaponActionFireBeamParams>
            </fireActions>
          </SCItemWeaponComponentParams>
          <SEntityComponentMiningLaserParams throttleMinimum="0.05">
            <miningLaserModifiers>
              <laserInstability><FloatModifierMultiplicative value="-35" /></laserInstability>
              <resistanceModifier><FloatModifierMultiplicative value="25" /></resistanceModifier>
              <optimalChargeWindowRateModifier><FloatModifierMultiplicative value="0" /></optimalChargeWindowRateModifier>
            </miningLaserModifiers>
            <filterParams>
              <filterModifier><FloatModifierMultiplicative value="30" /></filterModifier>
            </filterParams>
          </SEntityComponentMiningLaserParams>
          <SItemPortContainerComponentParams>
            <Ports>
              <SItemPortDef Name="consumable_1"><Types><SItemPortDefTypes Type="MiningModifier" /></Types></SItemPortDef>
              <SItemPortDef Name="consumable_2"><Types><SItemPortDefTypes Type="MiningModifier" /></Types></SItemPortDef>
              <SItemPortDef Name="vent"><Types><SItemPortDefTypes Type="WeaponAttachment" /></Types></SItemPortDef>
            </Ports>
          </SItemPortContainerComponentParams>
        XML

        mining = parsed_item("mining_laser_probe")["type_data"]["mining"]

        assert_in_delta 2340.0, mining["fracture_power_max"]
        assert_in_delta 117.0, mining["fracture_power_min"]
        assert_in_delta 1850.0, mining["extraction_power"]
        assert_in_delta 60.0, mining["optimal_range"]
        assert_in_delta 180.0, mining["max_range"]
        assert_in_delta 0.2, mining["charge_down_time"]
        assert_equal 2, mining["module_slots"]
        assert_equal({"instability" => -35.0, "resistance" => 25.0, "inert_materials" => -30.0}, mining["modifiers"])
      end

      test "reads an active mining module's uses, duration and effect on each beam" do
        write_item("mining_module_active_probe", name: "@item_Namemining_module_active_probe", category: "utility", type: "MiningModifier", sub_type: "Gun", components: <<~XML)
          <EntityComponentAttachableModifierParams activationMethod="ActivateOnDemand" charges="7">
            <modifiers>
              <ItemWeaponModifiersParams fireActionIndex="0">
                <weaponModifier><weaponStats damageMultiplier="1.5" /></weaponModifier>
              </ItemWeaponModifiersParams>
              <ItemWeaponModifiersParams fireActionIndex="1">
                <weaponModifier><weaponStats damageMultiplier="1" /></weaponModifier>
              </ItemWeaponModifiersParams>
              <ItemMiningModifierParams>
                <modifierLifetime><ItemModifierTimedLife lifetime="15" /></modifierLifetime>
                <MiningLaserModifier>
                  <resistanceModifier><FloatModifierMultiplicative value="-15.5" /></resistanceModifier>
                </MiningLaserModifier>
              </ItemMiningModifierParams>
            </modifiers>
          </EntityComponentAttachableModifierParams>
        XML

        type_data = parsed_item("mining_module_active_probe")["type_data"]

        assert type_data["mining_module"]
        assert_equal "active", type_data["activation"]
        assert_equal 7, type_data["charges"]
        assert_in_delta 15.0, type_data["duration"]
        assert_in_delta 50.0, type_data["fracture_power"]
        assert_nil type_data["extraction_power"]
        assert_equal({"resistance" => -15.5}, type_data["modifiers"])
      end

      test "reads a passive mining module's filter as less inert material, and no uses" do
        write_item("mining_module_passive_probe", name: "@item_Namemining_module_passive_probe", category: "utility", type: "MiningModifier", sub_type: "Gun", components: <<~XML)
          <EntityComponentAttachableModifierParams activationMethod="ActivateOnAttach" charges="1">
            <modifiers>
              <ItemWeaponModifiersParams fireActionIndex="1">
                <weaponModifier><weaponStats damageMultiplier="0.85" /></weaponModifier>
              </ItemWeaponModifiersParams>
              <MiningFilterItemModifierParams>
                <filterParams><filterModifier><FloatModifierMultiplicative value="20" /></filterModifier></filterParams>
              </MiningFilterItemModifierParams>
            </modifiers>
          </EntityComponentAttachableModifierParams>
        XML

        type_data = parsed_item("mining_module_passive_probe")["type_data"]

        assert_equal "passive", type_data["activation"]
        assert_nil type_data["charges"]
        assert_nil type_data["duration"]
        assert_in_delta(-15.0, type_data["extraction_power"])
        assert_equal({"inert_materials" => -20.0}, type_data["modifiers"])
      end

      test "reads a salvage modifier's multipliers, and nothing for one that scales nothing" do
        salvage = <<~XML
          <EntityComponentAttachableModifierParams activationMethod="ActivateOnDemand" charges="0">
            <modifiers>
              <ItemWeaponModifiersParams fireActionIndex="0">
                <weaponModifier><weaponStats><salvageModifier salvageSpeedMultiplier="%s" radiusMultiplier="%s" extractionEfficiency="1" /></weaponStats></weaponModifier>
              </ItemWeaponModifiersParams>
            </modifiers>
          </EntityComponentAttachableModifierParams>
        XML
        write_item("salvage_scraper_probe", name: "@item_Namesalvage_scraper_probe", category: "utility", type: "SalvageModifier", components: format(salvage, 0.6, 1.5))
        write_item("salvage_tractor_probe", name: "@item_Namesalvage_tractor_probe", category: "utility", type: "SalvageModifier", components: format(salvage, 1, 1))

        type_data = parsed_item("salvage_scraper_probe")["type_data"]

        assert type_data["salvage_modifier"]
        assert_in_delta 0.6, type_data["salvage_speed"]
        assert_in_delta 1.5, type_data["radius"]
        assert_in_delta 1.0, type_data["extraction_efficiency"]
        tractor = JSON.parse(File.read("#{@base_folder}/parsed/test/items/salvage_tractor_probe.json"))
        assert_nil tractor["type_data"]
      end

      test "reads the temperature model off the physics controller" do
        write_item("qdrv_hot", name: "@item_Nameqdrv_hot", components: temperature_xml(overheat: "1", signature: "1"))

        temperature = parsed_item("qdrv_hot")["temperature"]

        assert_equal(
          {
            "min_cooling_temperature" => 303.0,
            "overheat_temperature" => 383.0,
            "overheat_warning_temperature" => 373.0,
            "overheat_recovery_temperature" => 378.0,
            "misfire_min_temperature" => 380.0,
            "misfire_max_temperature" => 383.0,
            "ir_start_temperature" => 318.0,
            "ir_per_kelvin" => 10.0
          },
          temperature
        )
      end

      test "leaves out the overheat thresholds and IR of an item that uses neither" do
        write_item("powr_cool", name: "@item_Namepowr_cool", components: temperature_xml(overheat: "0", signature: "0"))

        assert_equal({"min_cooling_temperature" => 303.0}, parsed_item("powr_cool")["temperature"])
      end

      test "gives no temperature to an item whose model is switched off" do
        write_item("gun_cold", name: "@item_Namegun_cold", components: temperature_xml(enable: "0", overheat: "1", signature: "1"))

        assert_nil parsed_item("gun_cold")["temperature"]
      end

      test "reads the levels a component starts to misfire at, and its window" do
        write_item("shld_misfire", name: "@item_Nameshld_misfire", components: <<~XML)
          <EntityComponentMisfireParams maxWindowLength="600" minWindowLength="45">
            <triggerConditions>
              <SMisfireStatCondition degradation="1" damage="0.9" heat="0.8" distortion="0.6" />
            </triggerConditions>
          </EntityComponentMisfireParams>
        XML

        assert_equal(
          {"heat" => 0.8, "distortion" => 0.6, "damage" => 0.9, "wear" => 1.0, "min_window" => 45.0, "max_window" => 600.0},
          parsed_item("shld_misfire")["misfire"]
        )
      end

      test "gives no misfire to a component whose block names no stat levels" do
        write_item("batt_misfire", name: "@item_Namebatt_misfire", components: <<~XML)
          <EntityComponentMisfireParams maxWindowLength="120" minWindowLength="15">
            <triggerConditions>
              <SMisfireFunctionalityCondition functionalityMin="0" minTimeForTrigger="60" />
            </triggerConditions>
          </EntityComponentMisfireParams>
        XML

        assert_nil parsed_item("batt_misfire")["misfire"]
      end

      test "reads a quantum drive's heat per jump phase" do
        write_item("qdrv_heat", name: "@item_Nameqdrv_heat", components: <<~XML)
          <SCItemQuantumDriveParams quantumFuelRequirement="1" jumpRange="1" disconnectRange="1">
            <params driveSpeed="1" />
            <heatParams preRampUpThermalEnergyDraw="573" rampUpThermalEnergyDraw="600" inFlightThermalEnergyDraw="6000" rampDownThermalEnergyDraw="600" postRampDownThermalEnergyDraw="573" />
          </SCItemQuantumDriveParams>
        XML

        assert_equal(
          {"pre_ramp_up" => 573.0, "ramp_up" => 600.0, "in_flight" => 6000.0, "ramp_down" => 600.0, "post_ramp_down" => 573.0},
          parsed_item("qdrv_heat")["type_data"]["jump_heat"]
        )
      end

      private def temperature_xml(overheat:, signature:, enable: "1")
        <<~XML
          <SEntityPhysicsControllerParams>
            <PhysType>
              <SEntityRigidPhysicsControllerParams Mass="630">
                <temperature enable="#{enable}" initialTemperature="-1">
                  <signatureParams enable="#{signature}" minimumTemperatureForIR="318" temperatureToIR="10" />
                  <itemResourceParams minCoolingTemperature="303" enableOverheat="#{overheat}" overheatTemperature="383" overheatWarningTemperature="373" overheatRecoveryTemperature="378" />
                  <misfireTemperatureRange minimum="380" maximum="383" />
                </temperature>
              </SEntityRigidPhysicsControllerParams>
            </PhysType>
          </SEntityPhysicsControllerParams>
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
