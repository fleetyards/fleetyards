module ScData
  module Parser
    # What a piece of personal gear does, read from its record and the records
    # it points at: a gun's fire modes and its round, a tool's actions, what a
    # grenade, a mine or a pen does when it goes off.
    #
    # Every figure is the game's own except the ones a mode derives -- alpha,
    # DPS and how long it takes to overheat -- which follow from those.
    class GearStats
      include ScData::Parser::MiningModifiers

      DAMAGE_TYPES = {
        physical: "DamagePhysical",
        energy: "DamageEnergy",
        distortion: "DamageDistortion",
        thermal: "DamageThermal",
        biochemical: "DamageBiochemical",
        stun: "DamageStun"
      }.freeze

      FIRE_MODE_KINDS = %w[rapid single burst charged beam].freeze
      TOOL_ACTION_KINDS = %w[heal tractor salvage repair mining charge drain extinguish].freeze
      CONSUMABLE_EFFECT_KINDS = %w[health status buff].freeze

      PROJECTILE_ACTIONS = {
        "SWeaponActionFireRapidParams" => "rapid",
        "SWeaponActionFireSingleParams" => "single",
        "SWeaponActionFireBurstParams" => "burst"
      }.freeze

      # `gun_magazines` names the magazines some gun loads. A medgun's refill
      # and a multi-tool's canister name a round too -- one real energy guns
      # fire, so the round cannot tell them apart -- and a container stands
      # for its round only when a gun loads it. Without the set every
      # container keeps its round.
      def initialize(ammo_params: {}, ammo_containers: {}, consumable_subtypes: {}, melee_configs: {}, gun_magazines: nil, translate: ->(key) { key })
        @ammo_params = ammo_params
        @gun_magazines = gun_magazines
        @ammo_containers = ammo_containers
        @consumable_subtypes = consumable_subtypes
        @melee_configs = melee_configs
        @translate = translate
      end

      def call(values)
        components = values["Components"]
        return {} unless components.is_a?(Hash)

        weapon = hash(components["SCItemWeaponComponentParams"])
        container = ammo_container(components, weapon)
        ammo = @ammo_params[container&.dig("ammoParamsRecord")]
        secondary_ammo = @ammo_params[container&.dig("secondaryAmmoParamsRecord")]
        # A mode says which of the magazine's rounds it fires: the Arlington
        # loads a slug and a buckshot shell side by side.
        rounds = {"Primary" => round_damage(ammo), "Secondary" => round_damage(secondary_ammo)}
        heat = heat(weapon)
        actions = flatten_actions(weapon&.dig("fireActions"))
        magazine = magazine(container)

        # A rangefinder fires a mode that deals nothing, which is not one to
        # list, and a mode repeated under the same name is listed once.
        fire_modes = actions.filter_map { |action| fire_mode(action, rounds, heat) }
          .select { |mode| mode[:alpha] || mode[:dps] }
          .uniq
          .map { |mode| sustainable(mode, magazine) }

        # A medgun's vial and a multi-tool's battery still name a round, which
        # nothing fires. Only a gun, or the magazine a gun loads, has one.
        fires_rounds = fire_modes.any? { |mode| mode[:kind] != "beam" } ||
          (weapon.nil? && (@gun_magazines.nil? || @gun_magazines.include?(values["__ref"])))

        {
          fire_modes: fire_modes.presence,
          tool_actions: (actions + aim_actions(weapon)).filter_map { |action| tool_action(action) }.uniq.presence,
          ammo: (ammo(ammo) if fires_rounds),
          secondary_ammo: (ammo(secondary_ammo) if fires_rounds),
          magazine:,
          regen: regen(weapon),
          heat:,
          melee: melee(components),
          modifier: modifier(components),
          explosion: explosion(components),
          mine: mine(components),
          mining: mining(components),
          consumable: consumable(components)
        }.compact
      end

      # The magazines the guns among `records` load: those a weapon with a
      # projectile mode names.
      def self.gun_magazines(records)
        records.each_with_object(Set.new) do |values, magazines|
          weapon = values.is_a?(Hash) ? values.dig("Components", "SCItemWeaponComponentParams") : nil
          next unless weapon.is_a?(Hash) && fires_projectiles?(weapon["fireActions"])

          magazines << weapon["ammoContainerRecord"] if weapon["ammoContainerRecord"].present?
        end
      end

      private_class_method def self.fires_projectiles?(tree)
        case tree
        when Hash then tree.any? { |key, value| (PROJECTILE_ACTIONS.key?(key) || key == "SWeaponActionFireChargedParams") || fires_projectiles?(value) }
        when Array then tree.any? { |value| fires_projectiles?(value) }
        else false
        end
      end

      # The best a weapon does across its modes, for sorting a list by. A tool
      # that also cuts reports its beam the same way.
      def self.headline(stats)
        modes = Array.wrap(stats[:fire_modes])

        {
          alpha_damage: modes.filter_map { |mode| mode[:alpha] }.max,
          dps: modes.flat_map { |mode| [mode[:dps], mode.dig(:charge, :uncharged, :dps)] }.compact.max
        }
      end

      # A weapon names its magazine; a magazine, a medgun's vial or an
      # extinguisher's tank carries the container itself.
      private def ammo_container(components, weapon)
        magazine = @ammo_containers[weapon&.dig("ammoContainerRecord")]

        hash(magazine) || hash(components["SAmmoContainerComponentParams"])
      end

      private def magazine(container)
        return if container.blank?

        {
          size: integer(container["maxAmmoCount"]).then { |size| size if size&.positive? },
          reserve: integer(container["maxRestockCount"])
        }.compact.presence
      end

      private def ammo(ammo)
        return if ammo.blank?

        bullet = hash(ammo.dig("projectileParams", "BulletProjectileParams")) || {}
        drop = hash(bullet.dig("damageDropParams", "BulletDamageDropParams")) || {}
        pierce = hash(bullet["pierceabilityParams"]) || {}
        speed = number(ammo["speed"])
        lifetime = number(ammo["lifetime"])

        {
          damage: damage_map(bullet.dig("damage", "DamageInfo")),
          damage_drop: {
            min_distance: damage_map(drop.dig("damageDropMinDistance", "DamageInfo"))&.values&.max,
            per_meter: damage_map(drop.dig("damageDropPerMeter", "DamageInfo")),
            min_damage: damage_map(drop.dig("damageDropMinDamage", "DamageInfo"))
          }.compact.presence,
          speed:,
          lifetime:,
          range: ((speed * lifetime).round(1) if speed && lifetime),
          penetration: {
            max_thickness: positive(pierce["maxPenetrationThickness"]),
            near_radius: positive(bullet.dig("penetrationParams", "nearRadius")),
            far_radius: positive(bullet.dig("penetrationParams", "farRadius"))
          }.compact.presence,
          explosion: explosion_params(bullet.dig("detonationParams", "ProjectileDetonationParams", "explosionParams"))
        }.compact.presence
      end

      private def heat(weapon)
        heat = hash(weapon&.dig("connectionParams", "simplifiedHeatParams", "SWeaponSimplifiedHeatParams"))
        return if heat.blank?

        {
          overheat_temperature: positive(heat["overheatTemperature"]),
          cooling_per_second: positive(heat["coolingPerSecond"]),
          cooling_delay: positive(heat["timeTillCoolingStarts"]),
          overheat_fix_time: positive(heat["overheatFixTime"])
        }.compact.presence
      end

      # An energy weapon, a medgun's battery and an extinguisher refill a pool
      # rather than swap a magazine.
      private def regen(weapon)
        regen = hash(weapon&.dig("weaponRegenConsumerParams", "SWeaponRegenConsumerParams"))
        return if regen.blank?

        {
          capacity: positive(regen["maxAmmoLoad"]),
          regen_per_second: positive(regen["maxRegenPerSec"]),
          cooldown: positive(regen["regenerationCooldown"]),
          cost_per_shot: positive(regen["regenerationCostPerBullet"])
        }.compact.presence
      end

      # The modes a player switches between, each as one action. A sequence is
      # one mode; a mode that changes with the weapon's heat lists each of its
      # states; actions fired together -- only the multi-tool has any -- are
      # listed one by one, since each is a different tool.
      private def flatten_actions(fire_actions, condition: nil)
        entries(fire_actions).flat_map do |tag, params|
          case tag
          when "SWeaponActionDynamicConditionParams"
            default = flatten_actions(params["defaultWeaponAction"], condition:)
            conditional = Array.wrap(params.dig("conditionalWeaponActions", "SConditionalWeaponAction")).flat_map do |entry|
              flatten_actions(entry["weaponAction"], condition: condition(entry["condition"]))
            end

            (default + conditional).map { |action| action.merge(parent: params) }
          # The multi-tool's mining head fires a beam together with a scanner:
          # the beam is the head's laser, not something to shoot with.
          when "SWeaponActionParallelParams"
            mining = params.dig("weaponActions", "SWeaponActionMiningParams").present?

            flatten_actions(params["weaponActions"], condition:).map do |action|
              mining ? action.merge(mining: true, parent: params) : action
            end
          else
            [{tag:, params:, condition:}]
          end
        end
      end

      # The multi-tool's second button: which action it fires depends on the
      # head fitted -- a salvage head repairs, the tractor head pulls.
      private def aim_actions(weapon)
        entries(weapon&.dig("aimAction")).flat_map do |tag, params|
          next [] unless tag == "SWeaponActionConditionParams"

          Array.wrap(params.dig("conditionalWeaponActions", "SConditionalWeaponAction")).flat_map do |entry|
            flatten_actions(entry["weaponAction"])
          end
        end
      end

      private def condition(condition)
        heat = hash(condition&.dig("SWeaponConditionHeatLevel"))
        return if heat.blank?

        {
          heat_level: number(heat.dig("comparer", "value")),
          comparison: heat.dig("comparer", "mode")&.underscore
        }.compact.presence
      end

      private def fire_mode(action, rounds, heat)
        tag = action[:tag]
        params = action[:params]

        mode = case tag
        when *PROJECTILE_ACTIONS.keys then projectile_mode(PROJECTILE_ACTIONS[tag], params, rounds)
        when "SWeaponActionSequenceParams" then sequence_mode(params, rounds)
        when "SWeaponActionFireChargedParams" then charged_mode(params, rounds)
        when "SWeaponActionFireBeamParams" then beam_mode(params) unless action[:mining]
        end
        return if mode.nil?

        name = (action[:parent] || params)["name"]

        {
          name: value(name),
          label: label((action[:parent] || params)["localisedName"]),
          condition: action[:condition],
          **mode.except(:cadence),
          **overheat(mode, heat)
        }.compact
      end

      private def projectile_mode(kind, params, rounds)
        launcher = hash(params.dig("launchParams", "SProjectileLauncher")) || {}
        pellets = integer(launcher["pelletCount"]) || 1
        multiplier = number(launcher["damageMultiplier"]) || 1.0
        fire_rate = positive(params["fireRate"])
        shots = (kind == "burst") ? integer(params["shotCount"]) : nil
        cooldown = positive(params["cooldownTime"])
        alpha = alpha(round_for(rounds, launcher), pellets, multiplier)

        {
          kind:,
          fire_rate:,
          shots:,
          cooldown: (cooldown if kind == "burst"),
          pellets: (pellets if pellets > 1),
          ammo_cost: integer(launcher["ammoCost"]),
          damage_multiplier: (multiplier unless unit?(multiplier)),
          heat_per_shot: positive(params["heatPerShot"]),
          spread: spread(launcher["spreadParams"]),
          alpha:,
          dps: projectile_dps(alpha, fire_rate, shots, cooldown)
        }.compact
      end

      private def projectile_dps(alpha, fire_rate, shots, cooldown)
        return if alpha.nil? || fire_rate.nil?
        return round(alpha * fire_rate / 60) if shots.nil?

        cycle = (shots * 60 / fire_rate) + cooldown.to_f
        round(alpha * shots / cycle)
      end

      # A sequence fires its entries in turn at a cadence of its own -- a pump
      # shotgun's 375 rpm against the 455 its single action states. A step
      # lasts until the next may start, or until the burst it fires is done,
      # whichever is longer: the Pulse's 625 rpm sequence wraps a three-round
      # burst that takes 0.4s on its own.
      private def sequence_mode(params, rounds)
        steps = Array.wrap(params.dig("sequenceEntries", "SWeaponSequenceEntryParams")).filter_map do |entry|
          tag, action = entries(entry["weaponAction"]).first
          next unless PROJECTILE_ACTIONS.key?(tag)

          mode = projectile_mode(PROJECTILE_ACTIONS[tag], action, rounds)
          repetitions = integer(entry["repetitions"]) || 1
          delay = positive(entry["delay"])
          interval = (entry["unit"] == "RPM") ? (60 / delay if delay) : delay
          shots = mode[:shots] || 1
          own_time = mode[:fire_rate] ? (shots * 60 / mode[:fire_rate]) + mode[:cooldown].to_f : 0

          {mode:, shots: shots * repetitions, time: [interval.to_f, own_time].max * repetitions}
        end
        return if steps.empty?

        mode = steps.first[:mode]
        time = steps.sum { |step| step[:time] }
        shots = steps.sum { |step| step[:shots] }
        return mode unless time.positive?

        # Steps may fire different shots -- a slug, then buckshot -- so each
        # counts its own damage.
        dealt = steps.sum { |step| step[:mode][:alpha].to_f * step[:shots] }

        mode.merge(
          fire_rate: (mode[:kind] == "burst") ? mode[:fire_rate] : round(shots * 60 / time),
          dps: (round(dealt / time) if dealt.positive?),
          cadence: shots / time
        ).compact
      end

      # A charged shot fires the action it wraps, scaled by how far it was
      # charged. The figures here are the full charge's: the multiplier is a
      # plain factor (a railgun's round goes from 20 to 6,000), and a non-zero
      # pellet count replaces the shot's at full charge.
      private def charged_mode(params, rounds)
        tag, inner = entries(params["weaponAction"]).first
        base = PROJECTILE_ACTIONS.key?(tag) ? projectile_mode(PROJECTILE_ACTIONS[tag], inner, rounds) : {}
        modifier = hash(params["maxChargeModifier"]) || {}
        damage_multiplier = number(modifier["damageMultiplier"]) || 1.0
        pellets = integer(modifier["pellets"]).to_i.positive? ? integer(modifier["pellets"]) : (base[:pellets] || 1)
        launcher = hash(inner&.dig("launchParams", "SProjectileLauncher")) || {}
        alpha = alpha(round_for(rounds, launcher), pellets, (number(launcher["damageMultiplier"]) || 1.0) * damage_multiplier)
        charge_time = positive(params["chargeTime"])
        cooldown = positive(params["cooldownTime"])
        shot_time = (60 / base[:fire_rate] if base[:fire_rate])
        cycle = charge_time.to_f + [cooldown.to_f, shot_time.to_f].max

        base.merge(
          kind: "charged",
          pellets: (pellets if pellets > 1),
          charge: {
            time: charge_time,
            overcharge_time: positive(params["overchargeTime"]),
            overcharged_time: positive(params["overchargedTime"]),
            cooldown:,
            damage_multiplier: (damage_multiplier unless unit?(damage_multiplier)),
            projectile_speed_multiplier: positive(modifier["projectileSpeedMultiplier"]).then { |value| value unless unit?(value) },
            partial: flag(params["interpolateChargeBonus"]),
            # Released early, the shot goes out as the wrapped action fires it.
            uncharged: ({alpha: base[:alpha], dps: base[:dps]}.compact.presence unless flag(params["fireOnlyOnFullCharge"]))
          }.compact,
          alpha:,
          dps: (round(alpha / cycle) if alpha && cycle.positive?)
        ).compact
      end

      private def beam_mode(params)
        damage = damage_map(params.dig("damagePerSecond", "DamageInfo"))

        {
          kind: "beam",
          damage_per_second: damage,
          full_damage_range: positive(params["fullDamageRange"]),
          zero_damage_range: positive(params["zeroDamageRange"]),
          heat_per_second: positive(params["heatPerSecond"]),
          charge_up_time: positive(params["chargeUpTime"]),
          spread: spread(params["spreadParams"]),
          dps: (round(damage.values.sum) if damage)
        }.compact
      end

      # Shots and seconds of sustained fire before the weapon locks up. A
      # burst's cooldown and a charge's wait count: the shots a mode keeps up
      # per second are its DPS over its alpha, not its stated rate.
      #
      # Cooling only starts once the weapon has been quiet for its delay, so
      # it works between shots only where the mode pauses that long. A weapon
      # that sheds more heat in its pauses than it builds never locks up and
      # reports neither figure.
      private def overheat(mode, heat)
        limit = heat&.dig(:overheat_temperature)
        # A sequence knows its own cadence; its steps may differ in damage, so
        # its DPS over the first step's alpha would not give it.
        shots_per_second = mode[:cadence] || (mode[:dps] / mode[:alpha] if mode[:dps] && mode[:alpha]&.positive?)
        per_second = if mode[:heat_per_second]
          mode[:heat_per_second]
        elsif mode[:heat_per_shot] && shots_per_second
          mode[:heat_per_shot] * shots_per_second
        end
        return {} if limit.nil? || per_second.nil?

        net = per_second - (cools_between_shots?(mode, heat, shots_per_second) ? heat[:cooling_per_second].to_f : 0)
        return {} unless net.positive?

        seconds = limit / net

        {
          time_to_overheat: round(seconds),
          shots_to_overheat: (Integer(seconds * shots_per_second) if shots_per_second && mode[:heat_per_shot])
        }.compact
      end

      private def cools_between_shots?(mode, heat, shots_per_second)
        pause = case mode[:kind]
        when "beam" then 0
        when "burst" then mode[:cooldown].to_f
        when "charged" then mode.dig(:charge, :time).to_f
        else (shots_per_second ? 1 / shots_per_second : 0)
        end

        pause >= heat[:cooling_delay].to_f
      end

      private def tool_action(action)
        params = action[:params]

        data = case action[:tag]
        when "SWeaponActionFireBeamParams"
          if action[:mining]
            {
              kind: "mining",
              power: round(damage_map(params.dig("damagePerSecond", "DamageInfo")).to_h.values.sum).nonzero?,
              range: positive(params["zeroDamageRange"]),
              optimal_range: positive(params["fullDamageRange"]),
              charge_up_time: positive(params["chargeUpTime"])
            }
          end
        when "SWeaponActionFireHealingBeamParams"
          {
            kind: "heal",
            target: params["healingMode"]&.underscore,
            range: positive(params["maxDistance"]),
            sensor_range: positive(params["maxSensorDistance"]),
            dose_rate: positive(params["mSCUPerSec"]),
            ammo_per_dose: positive(params["ammoPerMSCU"]),
            battery_drain: positive(params["batteryDrainPerSec"])
          }
        when "SWeaponActionFireTractorBeamParams"
          {
            kind: "tractor",
            min_force: positive(params["minForce"]),
            max_force: positive(params["maxForce"]),
            min_distance: positive(params["minDistance"]),
            max_distance: positive(params["maxDistance"]),
            full_strength_distance: positive(params["fullStrengthDistance"]),
            max_angle: positive(params["maxAngle"]),
            max_volume: positive(params["maxVolume"]),
            max_speed: positive(params.dig("movementParams", "maxSpeed"))
          }
        when "SWeaponActionFireSalvageRepairParams"
          {
            kind: params["salvageRepairMode"]&.underscore,
            range: positive(params.dig("rangeParams", "maxBeamDistance")),
            health_rate: positive(params["maxHealthRepairRate"]),
            damage_map_rate: positive(params["maxDamageMapRepairRate"]),
            material_efficiency: positive(params["materialEfficiency"]),
            health_to_ammo_ratio: positive(params["healthToAmmoRatio"]),
            ramp_up_time: positive(params["rampUpTime"])
          }
        when "SWeaponActionFireChargeDrainParams"
          prime = hash(params["primeParams"]) || {}

          {
            kind: params["chargeDrainMode"]&.underscore,
            range: positive(params.dig("rangeParams", "maxBeamDistance")),
            resource_rate: positive(params["resourceRate"]),
            min_prime: positive(prime["minPrimeAmount"]),
            max_prime: positive(prime["maxPrimeAmount"]),
            prime_time: positive(prime["minToMaxChargeTime"]),
            overload_duration: positive(params["overloadDuration"])
          }
        when "SWeaponActionFireExtinguisherParams"
          {
            kind: "extinguish",
            range: positive(params["extinguishingRange"]),
            sensor_range: positive(params["sensorRange"]),
            cone_angle: positive(params["coneAngle"]),
            max_radius: positive(params["maxRadius"])
          }
        end
        return unless TOOL_ACTION_KINDS.include?(data&.dig(:kind))

        named = action[:parent] || params

        {name: value(named["name"]), label: label(named["localisedName"]), **data}.compact
      end

      # A blade's attacks, by the kind of blow: a slash and a stab can hit for
      # different amounts.
      private def melee(components)
        config = @melee_configs[components.dig("SMeleeWeaponComponentParams", "meleeCombatConfig")]
        attacks = Array.wrap(config&.dig("attackCategoryParams", "AttackCategoryParams")).filter_map do |attack|
          damage = damage_map(attack.dig("damageInfo"))
          next if damage.nil?

          {category: attack["actionCategory"]&.underscore, damage:, impulse: positive(attack["attackImpulse"])}.compact
        end

        {attacks: attacks.uniq}.presence if attacks.any?
      end

      # What an attachment does to the gun it sits on, as multipliers. Only the
      # figures it changes are kept.
      private def modifier(components)
        modifier = hash(components.dig("SWeaponModifierComponentParams", "modifier"))
        return if modifier.blank?

        stats = hash(modifier["weaponStats"]) || {}
        spread = hash(stats["spreadModifier"]) || {}
        recoil = hash(stats.dig("recoilModifier", "aimRecoilModifier", "curveRecoil")) || {}
        aim = hash(stats["aimModifier"]) || {}

        {
          damage: changed(stats["damageMultiplier"]),
          fire_rate: changed(stats["fireRateMultiplier"]),
          projectile_speed: changed(stats["projectileSpeedMultiplier"]),
          heat: changed(stats["heatGenerationMultiplier"]),
          sound_radius: changed(stats["soundRadiusMultiplier"]),
          spread: {
            min: changed(spread["minMultiplier"]),
            max: changed(spread["maxMultiplier"]),
            first_attack: changed(spread["firstAttackMultiplier"]),
            attack: changed(spread["attackMultiplier"]),
            decay: changed(spread["decayMultiplier"])
          }.compact.presence,
          recoil: {
            yaw: changed(recoil["yawMaxDegreesModifier"]),
            pitch: changed(recoil["pitchMaxDegreesModifier"])
          }.compact.presence,
          zoom: changed(aim["zoomScale"]),
          second_zoom: changed(aim["secondZoomScale"]),
          zoom_time: changed(aim["zoomTimeScale"])
        }.compact.presence
      end

      # A grenade on its fuse. The AI's copy of the trigger is left out: it
      # deals a fraction of the player's.
      private def explosion(components)
        trigger = Array.wrap(components.dig("EntityComponentTriggerableDevicesParams", "triggers", "STriggerableDevicesTriggerTimerParams")).first
        params = trigger&.dig("behavior", "STriggerableDevicesBehaviorExplosionParams", "explosionParams")
        params ||= components.dig("SHealthComponentParams", "DeathExplosionParams", "ExplosionParams") if components["SSensorMineComponentParams"]

        explosion = explosion_params(params)
        return if explosion.nil?

        explosion.merge(fuse: positive(trigger&.dig("duration"))).compact
      end

      private def explosion_params(params)
        params = hash(params)
        return if params.blank?

        {
          damage: damage_map(params.dig("damage", "DamageInfo")),
          min_radius: positive(params["minRadius"]),
          max_radius: positive(params["maxRadius"]),
          pressure: positive(params["pressure"])
        }.compact.presence
      end

      private def mine(components)
        trigger_type, trigger = entries(components.dig("SSensorMineComponentParams", "TriggerType")).first
        return if trigger.blank?

        {
          trigger: trigger_type.delete_prefix("SSensorMine").delete_suffix("Trigger").underscore,
          radius: positive(trigger["Radius"]),
          warning_radius: positive(trigger["WarningRadius"]),
          horizontal_angle: positive(trigger["AngleHorizontal"]),
          vertical_angle: positive(trigger["AngleVertical"]),
          length: positive(trigger["LaserLength"] || trigger["Length"])
        }.compact
      end

      # A gadget is stuck to the rock rather than fitted to the laser, and
      # files its modifiers under a block of its own -- with a cluster factor
      # no laser module has.
      private def mining(components)
        params = hash(components["EntityComponentAttachableModifierParams"])
        rock = hash(params&.dig("modifiers", "ItemMineableRockModifierParams", "MiningLaserModifier"))
        return if rock.nil?

        cluster = number(rock.dig("clusterFactorModifier", "FloatModifierMultiplicative", "value"))
        modifiers = (extract_mining_modifiers(rock, nil) || {}).merge(cluster_factor: cluster&.nonzero?).compact

        {
          modifiers: modifiers.presence,
          charges: integer(params["charges"]).then { |charges| charges if charges&.positive? }
        }.compact.presence
      end

      # What a pen, a pill or a drink does: the effects the game lists per
      # microSCU of its contents, scaled to a whole dose.
      private def consumable(components)
        params = hash(components["SCItemConsumableParams"])
        return if params.blank?

        volume = number(params.dig("consumableVolume", "SMicroCargoUnit", "microSCU"))
        contents = Array.wrap(params.dig("defaultContents", "ConsumableContent"))

        effects = contents.flat_map do |content|
          subtype = @consumable_subtypes[content["consumableSubtype"]]
          share = volume.to_f * (number(content["ratio"]) || 1.0)

          entries(subtype&.dig("effectsPerMicroSCU")).flat_map do |tag, effect|
            Array.wrap(effect).filter_map { |entry| consumable_effect(tag, entry, share) }
          end
        end

        {volume:, effects: merge_effects(effects).presence}.compact.presence
      end

      # A pen mixing several drugs lists the same body stat once per drug, and
      # a buff two of them share twice. A dose moves each stat by the sum.
      private def merge_effects(effects)
        merged = effects.group_by { |effect| effect.values_at(:kind, :stat, :buff) }.map do |(kind, _, _), same|
          next same.first unless %w[health status].include?(kind)

          same.first.merge(amount: round(same.sum { |effect| effect[:amount] }))
        end

        merged.reject { |effect| effect.key?(:amount) && effect[:amount].zero? }
      end

      private def consumable_effect(tag, effect, share)
        case tag
        when "ConsumableEffectHealth"
          amount = number(effect["healthChange"])
          {kind: "health", amount: round(amount * share)} if amount&.nonzero?
        when "ConsumableEffectModifyActorStatus"
          amount = number(effect["statPointChange"])
          {kind: "status", stat: effect["statType"]&.underscore, amount: round(amount * share)} if amount&.nonzero?
        when "ConsumableEffectAddBuffEffect"
          {
            kind: "buff",
            buff: effect["buffType"]&.underscore,
            duration: positive(effect.dig("buffDurationOverride", "BuffDurationOverride", "durationOverride"))
          }.compact
        end
      end

      private def spread(params)
        params = hash(params)
        params = hash(params["SSpreadParams"]) || params if params
        return if params.blank?

        {
          min: number(params["min"]),
          max: number(params["max"]),
          first_attack: number(params["firstAttack"]),
          attack: number(params["attack"]),
          decay: number(params["decay"])
        }.compact.presence
      end

      private def round_for(rounds, launcher)
        rounds[launcher["projectileType"]] || rounds["Primary"]
      end

      # A launcher that holds one round fires it and reloads, so the rate it
      # could fire at says nothing about the damage it keeps up.
      private def sustainable(mode, magazine)
        return mode unless magazine&.dig(:size) == 1

        mode = mode.except(:dps, :time_to_overheat, :shots_to_overheat)
        return mode unless mode.dig(:charge, :uncharged, :dps)

        uncharged = mode[:charge][:uncharged].except(:dps).presence
        mode.merge(charge: mode[:charge].merge(uncharged:).compact)
      end

      # What one round deals on a hit: the impact, and for a grenade or a
      # missile the blast it sets off, which is most of it. Kept apart because
      # pellets and a charge scale the impact, and a round explodes only once.
      private def round_damage(ammo)
        bullet = ammo&.dig("projectileParams", "BulletProjectileParams")
        impact = damage_map(bullet&.dig("damage", "DamageInfo"))
        blast = damage_map(bullet&.dig("detonationParams", "ProjectileDetonationParams", "explosionParams", "damage", "DamageInfo"))

        {impact:, blast:} if impact || blast
      end

      private def alpha(damage, pellets, multiplier)
        return if damage.nil?

        round((damage[:impact].to_h.values.sum * pellets * multiplier) + damage[:blast].to_h.values.sum)
      end

      private def damage_map(info)
        info = hash(info)
        return if info.blank?

        DAMAGE_TYPES.transform_values { |key| number(info[key]) }.compact.reject { |_, amount| amount.zero? }.presence
      end

      # Repeated children of one tag arrive as an array, a single one as a hash,
      # so every action list is read as tag-and-params pairs.
      private def entries(container)
        return [] unless container.is_a?(Hash)

        container.flat_map do |tag, params|
          Array.wrap(params).select { |entry| entry.is_a?(Hash) }.map { |entry| [tag, entry] }
        end
      end

      # The fire-mode names are written for the HUD -- "[SEMI]", "[AUTO]" --
      # so the brackets and the shouting go.
      private def label(key)
        return if key.blank? || key.include?("PLACEHOLDER") || key.include?("LOC_")

        text = @translate.call(key).to_s.delete("[]").strip
        return if text.blank? || text.start_with?("@")

        (text == text.upcase) ? text.capitalize : text
      end

      private def hash(value)
        value if value.is_a?(Hash)
      end

      private def value(value)
        value.presence
      end

      private def number(value)
        Float(value, exception: false)
      end

      private def positive(value)
        number = number(value)
        number if number&.positive?
      end

      private def integer(value)
        Integer(value, exception: false)
      end

      private def changed(value)
        number = number(value)
        number unless number.nil? || unit?(number)
      end

      private def unit?(value)
        value.nil? || (value - 1.0).abs < 1e-9
      end

      private def flag(value)
        value.to_s == "1"
      end

      private def round(value)
        value.round(2)
      end
    end
  end
end
