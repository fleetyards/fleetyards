# frozen_string_literal: true

require "test_helper"

module ScData
  module Parser
    class GearStatsTest < ActiveSupport::TestCase
      ROUND = "00000000-0000-0000-0000-00000000a001"
      SLUG = "00000000-0000-0000-0000-00000000a002"
      MAGAZINE = "00000000-0000-0000-0000-00000000b001"

      test "reads a burst mode's damage and how long it fires before overheating" do
        stats = stats_for(weapon(<<~XML, heat: true), rounds: {ROUND => round(energy: 21)})
          <SWeaponActionFireBurstParams name="Burst" localisedName="@FireMode_Burst" shotCount="3" fireRate="900" heatPerShot="2.8" cooldownTime="0.25">
            #{launcher}
          </SWeaponActionFireBurstParams>
        XML

        mode = stats[:fire_modes].sole

        assert_equal ["burst", 900.0, 3, 0.25, 21.0, 140.0], mode.values_at(:kind, :fire_rate, :shots, :cooldown, :alpha, :dps)
        # 6.67 shots a second once the cooldown between bursts is counted, and
        # no cooling: the 0.25s pause is shorter than the 1s cooling delay.
        assert_equal [5.36, 35], mode.values_at(:time_to_overheat, :shots_to_overheat)
        assert_equal({min: 0.05, max: 2.41, first_attack: 1.21, attack: 1.03, decay: 5.0}, mode[:spread])
        assert_equal({size: 45, reserve: 3}, stats[:magazine])
        assert_equal "Burst", mode[:label]
      end

      test "cools between shots only where the mode pauses longer than the cooling delay" do
        stats = stats_for(weapon(<<~XML, heat: true), rounds: {ROUND => round(energy: 50)})
          <SWeaponActionFireSingleParams name="Single" fireRate="30" heatPerShot="50">#{launcher}</SWeaponActionFireSingleParams>
        XML

        assert_equal [4.55, 2], stats[:fire_modes].sole.values_at(:time_to_overheat, :shots_to_overheat)
      end

      test "reads a charged shot at full charge, and what it deals released early" do
        stats = stats_for(weapon(<<~XML), rounds: {ROUND => round(energy: 10)})
          <SWeaponActionFireChargedParams name="Charge" localisedName="@FireMode_Charge" chargeTime="2.5" overchargeTime="5" overchargedTime="2" cooldownTime="0" interpolateChargeBonus="1" fireOnlyOnFullCharge="0">
            <maxChargeModifier damageMultiplier="1.25" projectileSpeedMultiplier="1" pellets="0" />
            <weaponAction>
              <SWeaponActionFireSingleParams name="Single" fireRate="60">#{launcher(pellets: 12)}</SWeaponActionFireSingleParams>
            </weaponAction>
          </SWeaponActionFireChargedParams>
        XML

        mode = stats[:fire_modes].sole

        assert_equal ["charged", 12, 150.0, 42.86], mode.values_at(:kind, :pellets, :alpha, :dps)
        assert_equal [2.5, 1.25, true], mode[:charge].values_at(:time, :damage_multiplier, :partial)
        assert_equal({alpha: 120.0, dps: 120.0}, mode.dig(:charge, :uncharged))
        assert_equal 120.0, GearStats.headline(stats)[:dps]
      end

      test "times a sequence by its own cadence or its burst, whichever takes longer" do
        stats = stats_for(weapon(<<~XML), rounds: {ROUND => round(energy: 21)})
          <SWeaponActionSequenceParams name="Burst" localisedName="@FireMode_Burst" mode="Looping">
            <sequenceEntries>
              <SWeaponSequenceEntryParams delay="625" unit="RPM" repetitions="1">
                <weaponAction>
                  <SWeaponActionFireBurstParams name="Burst" shotCount="3" fireRate="700" cooldownTime="0.15">#{launcher}</SWeaponActionFireBurstParams>
                </weaponAction>
              </SWeaponSequenceEntryParams>
            </sequenceEntries>
          </SWeaponActionSequenceParams>
          <SWeaponActionSequenceParams name="Shotgun" localisedName="@FireMode_Shotgun" mode="Looping">
            <sequenceEntries>
              <SWeaponSequenceEntryParams delay="375" unit="RPM" repetitions="1">
                <weaponAction>
                  <SWeaponActionFireSingleParams name="Shotgun" fireRate="455">#{launcher}</SWeaponActionFireSingleParams>
                </weaponAction>
              </SWeaponSequenceEntryParams>
            </sequenceEntries>
          </SWeaponActionSequenceParams>
        XML

        burst, single = stats[:fire_modes]

        assert_equal [700.0, 154.74], burst.values_at(:fire_rate, :dps)
        assert_equal [375.0, 131.25], single.values_at(:fire_rate, :dps)
      end

      test "counts each step of a sequence at its own damage" do
        rounds = {ROUND => round(physical: 10), SLUG => round(physical: 80)}
        stats = stats_for(weapon(<<~XML, primary: SLUG, secondary: ROUND), rounds:)
          <SWeaponActionSequenceParams name="Mixed" mode="Looping">
            <sequenceEntries>
              <SWeaponSequenceEntryParams delay="60" unit="RPM" repetitions="1">
                <weaponAction><SWeaponActionFireSingleParams name="Slug" fireRate="600">#{launcher(type: "Primary")}</SWeaponActionFireSingleParams></weaponAction>
              </SWeaponSequenceEntryParams>
              <SWeaponSequenceEntryParams delay="60" unit="RPM" repetitions="1">
                <weaponAction><SWeaponActionFireSingleParams name="Buck" fireRate="600">#{launcher(type: "Secondary", pellets: 8)}</SWeaponActionFireSingleParams></weaponAction>
              </SWeaponSequenceEntryParams>
            </sequenceEntries>
          </SWeaponActionSequenceParams>
        XML

        assert_equal 80.0, stats[:fire_modes].sole[:dps]
      end

      test "keeps no rate for a one-round launcher, charged or not" do
        stats = stats_for(weapon(<<~XML, magazine_size: 1), rounds: {ROUND => round(physical: 20)})
          <SWeaponActionFireChargedParams name="Charge" chargeTime="2" fireOnlyOnFullCharge="0">
            <maxChargeModifier damageMultiplier="300" />
            <weaponAction><SWeaponActionFireSingleParams name="Single" fireRate="70">#{launcher}</SWeaponActionFireSingleParams></weaponAction>
          </SWeaponActionFireChargedParams>
        XML

        mode = stats[:fire_modes].sole

        assert_nil mode[:dps]
        assert_equal({alpha: 20.0}, mode.dig(:charge, :uncharged))
        assert_nil GearStats.headline(stats)[:dps]
      end

      test "keeps a refill's round out, and a magazine's round in, though both name the same" do
        gun = Hash.from_xml("<Record>#{weapon(%(<SWeaponActionFireRapidParams name="Rapid" fireRate="600">#{launcher}</SWeaponActionFireRapidParams>))}</Record>").values.first
        magazines = GearStats.gun_magazines([gun])
        container = ->(ref) { %(<__ref>#{ref}</__ref><Components><SAmmoContainerComponentParams maxAmmoCount="40" ammoParamsRecord="#{ROUND}" /></Components>) }

        magazine = stats_for(container.call(MAGAZINE), rounds: {ROUND => round(energy: 18)}, gun_magazines: magazines)
        refill = stats_for(container.call("00000000-0000-0000-0000-00000000b009"), rounds: {ROUND => round(energy: 18)}, gun_magazines: magazines)

        assert_equal({energy: 18.0}, magazine.dig(:ammo, :damage))
        assert_nil refill[:ammo]
      end

      test "times a mixed sequence's overheat by its cadence, not its DPS over one step's damage" do
        rounds = {ROUND => round(physical: 10), SLUG => round(physical: 90)}
        stats = stats_for(weapon(<<~XML, heat: true, primary: SLUG, secondary: ROUND), rounds:)
          <SWeaponActionSequenceParams name="Mixed" mode="Looping">
            <sequenceEntries>
              <SWeaponSequenceEntryParams delay="60" unit="RPM" repetitions="1">
                <weaponAction><SWeaponActionFireSingleParams name="Slug" fireRate="600" heatPerShot="10">#{launcher(type: "Primary")}</SWeaponActionFireSingleParams></weaponAction>
              </SWeaponSequenceEntryParams>
              <SWeaponSequenceEntryParams delay="60" unit="RPM" repetitions="1">
                <weaponAction><SWeaponActionFireSingleParams name="Buck" fireRate="600" heatPerShot="10">#{launcher(type: "Secondary")}</SWeaponActionFireSingleParams></weaponAction>
              </SWeaponSequenceEntryParams>
            </sequenceEntries>
          </SWeaponActionSequenceParams>
        XML

        mode = stats[:fire_modes].sole

        # One shot a second at 10 heat a shot, cooling 3 once the 1s pause is
        # reached: 7 heat a second, 100 to overheat.
        assert_equal [14.29, 14], mode.values_at(:time_to_overheat, :shots_to_overheat)
        assert_not mode.key?(:cadence)
      end

      test "lists each state of a mode that changes with the weapon's heat" do
        stats = stats_for(weapon(<<~XML), rounds: {ROUND => round(energy: 21)})
          <SWeaponActionDynamicConditionParams name="RapidBeam" localisedName="@LOC_PLACEHOLDER">
            <conditionalWeaponActions>
              <SConditionalWeaponAction>
                <condition><SWeaponConditionHeatLevel><comparer mode="GreaterOrEqual" value="0.4" /></SWeaponConditionHeatLevel></condition>
                <weaponAction>
                  <SWeaponActionFireBeamParams fullDamageRange="65" zeroDamageRange="65" heatPerSecond="17">
                    <damagePerSecond><DamageInfo DamageEnergy="210" DamageDistortion="50" /></damagePerSecond>
                  </SWeaponActionFireBeamParams>
                </weaponAction>
              </SConditionalWeaponAction>
            </conditionalWeaponActions>
            <defaultWeaponAction>
              <SWeaponActionFireRapidParams name="Rapid" fireRate="600">#{launcher}</SWeaponActionFireRapidParams>
            </defaultWeaponAction>
          </SWeaponActionDynamicConditionParams>
        XML

        rapid, beam = stats[:fire_modes]

        assert_equal ["rapid", 210.0, nil], rapid.values_at(:kind, :dps, :condition)
        assert_equal ["beam", 260.0, {heat_level: 0.4, comparison: "greater_or_equal"}], beam.values_at(:kind, :dps, :condition)
        assert_equal({energy: 210.0, distortion: 50.0}, beam[:damage_per_second])
      end

      test "fires each mode's own round when the magazine loads two" do
        rounds = {ROUND => round(physical: 12.5), SLUG => round(physical: 80)}
        stats = stats_for(weapon(<<~XML, secondary: ROUND, primary: SLUG), rounds:)
          <SWeaponActionFireSingleParams name="Slug" fireRate="85">#{launcher(type: "Primary")}</SWeaponActionFireSingleParams>
          <SWeaponActionFireSingleParams name="Buckshot" fireRate="85">#{launcher(type: "Secondary", pellets: 8)}</SWeaponActionFireSingleParams>
        XML

        assert_equal [80.0, 100.0], stats[:fire_modes].pluck(:alpha)
        assert_equal({physical: 12.5}, stats.dig(:secondary_ammo, :damage))
      end

      test "counts a round's blast in its damage, and keeps no rate for a one-round launcher" do
        rounds = {ROUND => round(physical: 20, blast: {physical: 20_000, energy: 21_000})}
        stats = stats_for(weapon(<<~XML, magazine_size: 1), rounds:)
          <SWeaponActionFireSingleParams name="Single" fireRate="500">#{launcher}</SWeaponActionFireSingleParams>
        XML

        mode = stats[:fire_modes].sole

        assert_equal 41_020.0, mode[:alpha]
        assert_nil mode[:dps]
        assert_equal({physical: 20_000.0, energy: 21_000.0}, stats.dig(:ammo, :explosion, :damage))
      end

      test "reads a medgun's dosing and leaves out the round its vial names" do
        stats = stats_for(weapon(<<~XML), rounds: {ROUND => round(energy: 18)})
          <SWeaponActionFireHealingBeamParams name="Heal" localisedName="@LOC_PLACEHOLDER" healingMode="Target" maxDistance="2.5" maxSensorDistance="20" mSCUPerSec="10" ammoPerMSCU="1" />
          <SWeaponActionFireHealingBeamParams name="SelfHeal" localisedName="@LOC_PLACEHOLDER" healingMode="Self" maxDistance="1.5" mSCUPerSec="10" ammoPerMSCU="1" />
        XML

        assert_equal [["heal", "target", 2.5, 10.0], ["heal", "self", 1.5, 10.0]],
          stats[:tool_actions].map { |action| action.values_at(:kind, :target, :range, :dose_rate) }
        assert_nil stats[:fire_modes]
        assert_nil stats[:ammo]
      end

      test "reads the multi-tool's mining head as a tool rather than a gun" do
        stats = stats_for(weapon(<<~XML))
          <SWeaponActionParallelParams name="Mining beam and scanning" localisedName="@ui_weapons_multi_mining">
            <weaponActions>
              <SWeaponActionFireBeamParams fullDamageRange="10" zeroDamageRange="10" chargeUpTime="0.1">
                <damagePerSecond><DamageInfo DamageEnergy="0.1" /></damagePerSecond>
              </SWeaponActionFireBeamParams>
              <SWeaponActionMiningParams scanningAlwaysActive="1" />
            </weaponActions>
          </SWeaponActionParallelParams>
          <SWeaponActionFireTractorBeamParams name="TractorBeam" localisedName="@ui_weapons_multi_tractor" minForce="500" maxForce="257500" maxDistance="150" fullStrengthDistance="3" maxAngle="40" maxVolume="20" />
        XML

        mining, tractor = stats[:tool_actions]

        assert_nil stats[:fire_modes]
        assert_equal ["mining", "Mining", 0.1, 10.0], mining.values_at(:kind, :label, :power, :range)
        assert_equal ["tractor", 257_500.0, 150.0], tractor.values_at(:kind, :max_force, :max_distance)
      end

      test "reads the multi-tool's second button for each head it takes" do
        stats = stats_for(<<~XML)
          <Components>
            <SCItemWeaponComponentParams>
              <aimAction>
                <SWeaponActionConditionParams>
                  <conditionalWeaponActions>
                    <SConditionalWeaponAction>
                      <weaponAction>
                        <SWeaponActionFireSalvageRepairParams name="Repair" salvageRepairMode="Repair" maxHealthRepairRate="95">
                          <rangeParams maxBeamDistance="5" />
                        </SWeaponActionFireSalvageRepairParams>
                      </weaponAction>
                    </SConditionalWeaponAction>
                    <SConditionalWeaponAction>
                      <weaponAction>
                        <SWeaponActionFireTractorBeamParams name="TractorBeam" maxForce="257500" maxDistance="150" />
                      </weaponAction>
                    </SConditionalWeaponAction>
                  </conditionalWeaponActions>
                </SWeaponActionConditionParams>
              </aimAction>
            </SCItemWeaponComponentParams>
          </Components>
        XML

        assert_equal [["repair", 95.0, 5.0], ["tractor", nil, nil]],
          stats[:tool_actions].map { |action| action.values_at(:kind, :health_rate, :range) }
      end

      test "reads a grenade's blast on its fuse and ignores the AI's weaker copy" do
        stats = stats_for(<<~XML)
          <Components>
            <EntityComponentTriggerableDevicesParams>
              <triggers>
                <STriggerableDevicesTriggerTimerParams duration="5">
                  <behavior><STriggerableDevicesBehaviorExplosionParams>
                    <explosionParams minRadius="4" maxRadius="5.5" pressure="280"><damage><DamageInfo DamagePhysical="120" /></damage></explosionParams>
                  </STriggerableDevicesBehaviorExplosionParams></behavior>
                </STriggerableDevicesTriggerTimerParams>
              </triggers>
              <aiTriggers>
                <STriggerableDevicesTriggerTimerParams duration="5">
                  <behavior><STriggerableDevicesBehaviorExplosionParams>
                    <explosionParams minRadius="4" maxRadius="5.5"><damage><DamageInfo DamagePhysical="14" /></damage></explosionParams>
                  </STriggerableDevicesBehaviorExplosionParams></behavior>
                </STriggerableDevicesTriggerTimerParams>
              </aiTriggers>
            </EntityComponentTriggerableDevicesParams>
          </Components>
        XML

        assert_equal({damage: {physical: 120.0}, min_radius: 4.0, max_radius: 5.5, pressure: 280.0, fuse: 5.0}, stats[:explosion])
      end

      test "reads a mine's trigger and the blast it sets off" do
        stats = stats_for(<<~XML)
          <Components>
            <SSensorMineComponentParams FriendlyFire="1">
              <TriggerType><SSensorMineLaserTrigger LaserLength="2" /></TriggerType>
            </SSensorMineComponentParams>
            <SHealthComponentParams>
              <DeathExplosionParams>
                <ExplosionParams minRadius="0.5" maxRadius="5" pressure="200"><damage><DamageInfo DamagePhysical="210" /></damage></ExplosionParams>
              </DeathExplosionParams>
            </SHealthComponentParams>
          </Components>
        XML

        assert_equal({trigger: "laser", length: 2.0}, stats[:mine])
        assert_equal({physical: 210.0}, stats.dig(:explosion, :damage))
      end

      test "scales a pen's effects to its whole dose" do
        coagulant = "00000000-0000-0000-0000-00000000c001"
        subtypes = {coagulant => Hash.from_xml(<<~XML).values.first}
          <ConsumableSubtype __ref="#{coagulant}" typeName="Coagulant">
            <effectsPerMicroSCU>
              <ConsumableEffectHealth healthChange="3.75" />
              <ConsumableEffectModifyActorStatus statType="BloodDrugLevel" statPointChange="0.5" />
              <ConsumableEffectModifyActorStatus statType="BloodDrugLevel" statPointChange="0.5" />
              <ConsumableEffectAddBuffEffect buffType="RadiationAntidote">
                <buffDurationOverride><BuffDurationOverride durationOverride="10" /></buffDurationOverride>
              </ConsumableEffectAddBuffEffect>
            </effectsPerMicroSCU>
          </ConsumableSubtype>
        XML

        stats = stats_for(<<~XML, consumable_subtypes: subtypes)
          <Components>
            <SCItemConsumableParams>
              <consumableVolume><SMicroCargoUnit microSCU="30" /></consumableVolume>
              <defaultContents><ConsumableContent consumableSubtype="#{coagulant}" ratio="1" /></defaultContents>
            </SCItemConsumableParams>
          </Components>
        XML

        assert_equal [
          {kind: "health", amount: 112.5},
          {kind: "status", stat: "blood_drug_level", amount: 30.0},
          {kind: "buff", buff: "radiation_antidote", duration: 10.0}
        ], stats.dig(:consumable, :effects)
      end

      test "keeps only what an attachment changes" do
        stats = stats_for(<<~XML)
          <Components>
            <SWeaponModifierComponentParams>
              <modifier>
                <weaponStats damageMultiplier="1" fireRateMultiplier="1" soundRadiusMultiplier="1.2">
                  <recoilModifier><aimRecoilModifier><curveRecoil yawMaxDegreesModifier="0.8" pitchMaxDegreesModifier="0.8" /></aimRecoilModifier></recoilModifier>
                  <spreadModifier minMultiplier="1" maxMultiplier="0.9" />
                  <aimModifier zoomScale="4" secondZoomScale="1" />
                </weaponStats>
              </modifier>
            </SWeaponModifierComponentParams>
          </Components>
        XML

        assert_equal({sound_radius: 1.2, spread: {max: 0.9}, recoil: {yaw: 0.8, pitch: 0.8}, zoom: 4.0}, stats[:modifier])
      end

      test "reads what a mining gadget does to the rock it sits on" do
        stats = stats_for(<<~XML)
          <Components>
            <EntityComponentAttachableModifierParams activationMethod="ActivateOnDemand" charges="-1">
              <modifiers>
                <ItemMineableRockModifierParams>
                  <MiningLaserModifier>
                    <laserInstability><FloatModifierMultiplicative value="-70" /></laserInstability>
                    <resistanceModifier><FloatModifierMultiplicative value="10" /></resistanceModifier>
                    <clusterFactorModifier><FloatModifierMultiplicative value="30" /></clusterFactorModifier>
                  </MiningLaserModifier>
                </ItemMineableRockModifierParams>
              </modifiers>
            </EntityComponentAttachableModifierParams>
          </Components>
        XML

        assert_equal({modifiers: {instability: -70.0, resistance: 10.0, cluster_factor: 30.0}}, stats[:mining])
      end

      test "reads a blade's attacks from its combat config" do
        config = "00000000-0000-0000-0000-00000000d001"
        melee = {config => Hash.from_xml(<<~XML).values.first}
          <MeleeCombatConfig __ref="#{config}">
            <attackCategoryParams>
              <AttackCategoryParams actionCategory="BladeSlash" attackImpulse="20"><damageInfo DamagePhysical="30" /></AttackCategoryParams>
              <AttackCategoryParams actionCategory="BladeStab" attackImpulse="20"><damageInfo DamagePhysical="30" /></AttackCategoryParams>
            </attackCategoryParams>
          </MeleeCombatConfig>
        XML

        stats = stats_for(%(<Components><SMeleeWeaponComponentParams meleeCombatConfig="#{config}" /></Components>), melee_configs: melee)

        assert_equal %w[blade_slash blade_stab], stats.dig(:melee, :attacks).pluck(:category)
        assert_equal({physical: 30.0}, stats.dig(:melee, :attacks, 0, :damage))
      end

      private def stats_for(components, rounds: {}, consumable_subtypes: {}, melee_configs: {}, containers: @containers || {}, gun_magazines: nil)
        values = Hash.from_xml("<Record>#{components}</Record>").values.first

        GearStats.new(
          ammo_params: rounds,
          ammo_containers: containers,
          consumable_subtypes:,
          melee_configs:,
          gun_magazines:,
          translate: ->(key) { {"@FireMode_Burst" => "[BURST]", "@ui_weapons_multi_mining" => "Mining"}[key] }
        ).call(values)
      end

      private def weapon(fire_actions, heat: false, primary: ROUND, secondary: nil, magazine_size: 45)
        @containers = {
          MAGAZINE => {
            "maxAmmoCount" => magazine_size.to_s,
            "maxRestockCount" => "3",
            "ammoParamsRecord" => primary,
            "secondaryAmmoParamsRecord" => secondary
          }.compact
        }

        heat_params = <<~XML if heat
          <connectionParams>
            <simplifiedHeatParams>
              <SWeaponSimplifiedHeatParams overheatTemperature="100" coolingPerSecond="3" timeTillCoolingStarts="1" />
            </simplifiedHeatParams>
          </connectionParams>
        XML

        <<~XML
          <Components>
            <SCItemWeaponComponentParams ammoContainerRecord="#{MAGAZINE}">
              #{heat_params}
              <fireActions>#{fire_actions}</fireActions>
            </SCItemWeaponComponentParams>
          </Components>
        XML
      end

      private def launcher(pellets: 1, type: "Primary")
        <<~XML
          <launchParams>
            <SProjectileLauncher ammoCost="1" pelletCount="#{pellets}" damageMultiplier="1" projectileType="#{type}">
              <spreadParams min="0.05" max="2.41" firstAttack="1.21" attack="1.03" decay="5" />
            </SProjectileLauncher>
          </launchParams>
        XML
      end

      private def round(blast: nil, **damage)
        info = damage.map { |type, amount| %(Damage#{type.to_s.capitalize}="#{amount}") }.join(" ")
        blast_info = blast&.map { |type, amount| %(Damage#{type.to_s.capitalize}="#{amount}") }&.join(" ")
        detonation = <<~XML if blast
          <detonationParams><ProjectileDetonationParams>
            <explosionParams minRadius="1.5" maxRadius="1.5"><damage><DamageInfo #{blast_info} /></damage></explosionParams>
          </ProjectileDetonationParams></detonationParams>
        XML

        Hash.from_xml(<<~XML).values.first
          <AmmoParams speed="550" lifetime="2">
            <projectileParams>
              <BulletProjectileParams>
                <damage><DamageInfo #{info} /></damage>
                #{detonation}
              </BulletProjectileParams>
            </projectileParams>
          </AmmoParams>
        XML
      end
    end
  end
end
