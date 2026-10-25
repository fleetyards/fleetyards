# frozen_string_literal: true

# A fitting's firepower without anyone's pips, as the hangar filters and sorts
# on it: alpha and burst DPS with the guns powered, and sustained DPS at the
# least weapon power that fires them -- one pip -- and at the most the plant
# can give them.
#
# The ship page works the same figures out in the browser
# (`computeFirepower` in `useLoadoutStats.ts`), from the same tree the
# hardpoints endpoint renders: `{category:, component: {type:, size:,
# type_data:}, hardpoints: [...]}`. The two are held to one answer by the
# fixtures under `test/fixtures/loadout_stats`, which both test suites read;
# a change to one side's arithmetic has to land on the other.
class LoadoutFirepower
  # Bumped with any change to what the figures mean, so the stored ones that
  # predate it can be told apart.
  VERSION = 1

  ORDNANCE_CATEGORIES = %w[weapons missiles bombs].freeze

  POWER_FAMILY_BY_CATEGORY = {
    "weapons" => "weapon",
    "weapon_mounts" => "weapon",
    "turret" => "weapon",
    "shieldgenerator" => "shield",
    "cooler" => "coolers",
    "radar" => "radar",
    "quantumdrive" => "qdrive",
    "quantumenforcementdevice" => "qed",
    "emp" => "emp",
    "lifesupport" => "lifeSupport",
    "controller" => "engine",
    "salvagemunching" => "salvage"
  }.freeze

  # Beams and mining lasers draw segments of their own rather than from the
  # guns' shared pool.
  POWER_FAMILY_BY_TYPE = {
    "TractorBeam" => "tractorBeam",
    "TowingBeam" => "towingbeam",
    "WeaponMining" => "miningLaser"
  }.freeze

  # Ships run the first two shields; the rest are unpowered backups.
  SHIELD_MAX_ITEM_COUNT = 2

  DAMAGE_TYPES = %w[physical energy distortion thermal].freeze

  NO_REGEN_MODIFIER = {"power_ratio" => 1, "max_ammo_load" => 1, "max_regen_per_second" => 1}.freeze

  Result = Struct.new(:alpha, :burst_dps, :sustained_dps_min, :sustained_dps_max)

  # A `FittingTree`'s firepower, with the ship's weapon pool and engineering
  # buff.
  def self.for_tree(tree, model)
    new(tree, weapon_pool_size: model.weapon_pool_size, regen_modifier: model.weapon_regen_modifier).call
  end

  # `hardpoints` with string keys in snake case.
  def initialize(hardpoints, weapon_pool_size: nil, regen_modifier: nil)
    @hardpoints = Array(hardpoints)
    @pool = weapon_pool_size.to_i
    @modifier = NO_REGEN_MODIFIER.merge(regen_modifier.to_h.transform_keys(&:to_s).compact)
  end

  def call
    collect_power(@hardpoints)
    weapons = collect_weapons(@hardpoints)

    at_max = tally(weapons, max_ratio)
    at_min = tally(weapons, min_ratio)

    Result.new(
      alpha: at_max[:alpha],
      burst_dps: at_max[:burst],
      sustained_dps_min: at_min[:sustained],
      sustained_dps_max: at_max[:sustained]
    )
  end

  private def boost
    numeric(@modifier["power_ratio"]).then { |value| value.zero? ? 1 : value }
  end

  # The guns at their most: every family keeps only its mandatory block, and
  # the guns fill their pool with what is left.
  private def max_ratio
    @max_ratio ||= [1, weapon_max_ratio * boost].min
  end

  private def weapon_max_ratio
    consumption = @weapon_units.ceil
    return 1 if @pool <= 0 || consumption <= 0

    uncapped = [1, @pool / @weapon_units].min
    return uncapped if segments <= 0

    enabled = [@pool, consumption].min
    weapon_max = (segments - @non_weapon_critical).clamp(0, enabled)
    [uncapped, weapon_max / @weapon_units].min
  end

  private def min_ratio
    one_pip = if @pool <= 0 || @weapon_units <= 0
      1
    else
      [1, (1.0 / @weapon_units) * boost].min
    end

    [max_ratio, one_pip].min
  end

  # A single plant yields its units; more add their sizes for every plant past
  # the first.
  private def segments
    @segments ||= if @plants.empty?
      0
    else
      units = @plants.sum { |plant| js_round(plant[:units] / @plants.size) }
      units + (@plants.size - 1) * @plants.sum { |plant| plant[:size] }
    end
  end

  private def collect_power(hardpoints)
    @plants = []
    @weapon_units = 0.0
    @non_weapon_critical = 0
    @shields_seen = 0
    walk_power(hardpoints)
  end

  private def walk_power(hardpoints)
    hardpoints.each do |hardpoint|
      component = hardpoint["component"]
      type_data = component&.dig("type_data")
      category = hardpoint["category"]

      if type_data.is_a?(Hash) && category.present?
        if category == "powerplant"
          units = numeric(type_data["power_base"])
          @plants << {units:, size: numeric(component["size"])} if units > 0
        else
          family = POWER_FAMILY_BY_TYPE[component["type"]] || POWER_FAMILY_BY_CATEGORY[category]
          draw = numeric(type_data["power_consumption"])

          if family == "weapon"
            @weapon_units += draw
          elsif family && draw > 0 && !(family == "shield" && (@shields_seen += 1) > SHIELD_MAX_ITEM_COUNT)
            fraction = type_data["power_minimum_fraction"].nil? ? nil : numeric(type_data["power_minimum_fraction"])
            @non_weapon_critical += critical_size(draw, fraction)
          end
        end
      end

      walk_power(Array(hardpoint["hardpoints"]))
    end
  end

  private def critical_size(units, minimum_fraction)
    return 0 if units <= 0

    fraction = (minimum_fraction.nil? || minimum_fraction.zero?) ? 1.0 / units : minimum_fraction
    js_round(units * fraction)
  end

  # A mining laser's beam damage is what it does to a rock.
  private def collect_weapons(hardpoints, collected = [])
    hardpoints.each do |hardpoint|
      type_data = hardpoint.dig("component", "type_data")

      if ORDNANCE_CATEGORIES.include?(hardpoint["category"]) && type_data.is_a?(Hash) && type_data["mining"].blank?
        collected << type_data
      end

      collect_weapons(Array(hardpoint["hardpoints"]), collected)
    end

    collected
  end

  private def tally(weapons, power_ratio)
    powered = (power_ratio > 0) ? 1 : 0
    totals = {alpha: 0.0, burst: 0.0, sustained: 0.0}

    weapons.each do |weapon|
      ratio = duty_cycle(weapon, power_ratio) * powered

      if weapon["beam"] && weapon["damage_per_second"]
        totals[:burst] += damage(weapon["damage_per_second"], powered)
        totals[:sustained] += damage(weapon["damage_per_second"], ratio)
      elsif !missile?(weapon) && truthy_number?(weapon["fire_rate"]) && weapon["damage_per_shot"]
        pellets = truthy_number?(weapon["pellets_per_shot"]) ? weapon["pellets_per_shot"] : 1
        rate = shots_per_second(weapon)
        totals[:alpha] += damage(weapon["damage_per_shot"], pellets * powered)
        totals[:burst] += damage(weapon["damage_per_shot"], rate * powered)
        totals[:sustained] += damage(weapon["damage_per_shot"], rate * ratio)
      end
    end

    totals
  end

  # Summed type by type, in the order the browser adds them, so both land on
  # the same floating-point figure.
  private def damage(breakdown, multiplier)
    return 0.0 unless breakdown.is_a?(Hash)

    DAMAGE_TYPES.sum(0.0) do |type|
      value = breakdown[type]
      (value.is_a?(Numeric) && value > 0) ? value * multiplier : 0.0
    end
  end

  private def missile?(weapon)
    weapon.key?("tracking_signal")
  end

  private def shots_per_second(weapon)
    pellets = truthy_number?(weapon["pellets_per_shot"]) ? weapon["pellets_per_shot"] : 1
    (pellets * (weapon["fire_rate"] || 0)) / 60.0
  end

  # The share of the time a gun fires: until its capacitor drains or its heat
  # locks it out, then through the cooldown and the recharge.
  private def duty_cycle(weapon, power_ratio)
    fire_rate = truthy_number?(weapon["fire_rate"]) ? weapon["fire_rate"] / 60.0 : 0
    return 1 if fire_rate <= 0

    regen = weapon["regen"].is_a?(Hash) ? weapon["regen"] : {}
    if truthy_number?(regen["max_regen_per_second"]) && truthy_number?(regen["max_ammo_load"])
      pool = js_round(regen["max_ammo_load"] * power_ratio * numeric(@modifier["max_ammo_load"]))
      regen_per_second = regen["max_regen_per_second"] * power_ratio * numeric(@modifier["max_regen_per_second"])
      return 0 if pool <= 0 || regen_per_second <= 0

      time_firing = pool / fire_rate
      off_time = (regen["regeneration_cooldown"] || 0) + pool / regen_per_second
      return time_firing / (time_firing + off_time)
    end

    heat = weapon["heat"].is_a?(Hash) ? weapon["heat"] : {}
    if truthy_number?(heat["overheat_temperature"]) && truthy_number?(weapon["heat_per_shot"]) && truthy_number?(heat["overheat_fix_time"])
      time_firing = heat["overheat_temperature"] / (weapon["heat_per_shot"] * fire_rate)
      return time_firing / (time_firing + heat["overheat_fix_time"])
    end

    1
  end

  # JavaScript's truthiness for a figure: a number other than zero.
  private def truthy_number?(value)
    value.is_a?(Numeric) && !value.zero?
  end

  private def numeric(value)
    number = Float(value, exception: false)
    (number.nil? || !number.finite?) ? 0.0 : number
  end

  # `Math.round`: halves go up, where Ruby's `round` goes away from zero. The
  # same for every figure here, which are never negative.
  private def js_round(value)
    (value + 0.5).floor
  end
end
