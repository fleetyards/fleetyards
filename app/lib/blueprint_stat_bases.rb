# frozen_string_literal: true

# The value a quality modifier multiplies.
#
# A modifier states a factor -- 0.80x at quality 0 rising to 1.20x at 1,000 --
# and says nothing about what it is a factor of. The stat it moves is named by
# `property_key`, and the figure itself is the one the catalogue already holds
# for the crafted item, so the two are matched up here.
#
# Every ramp in the build is centred on 1.0x at quality 500: the single-segment
# ones are symmetric about it and the piecewise ones put their seam there. The
# catalogue's own value is therefore the quality-500 value, which is what makes
# `base * modifier` well defined rather than a guess.
#
# Only keys that resolve to a figure we actually store appear below. The rest
# -- component health, weapon recoil, quantum fuel burn, hull scraping -- have
# no counterpart in the catalogue, and the page keeps showing their factor
# rather than inventing a number to multiply.
class BlueprintStatBases
  EQUIPMENT = {
    "gpp_armor_damagemitigation" => :damage_reduction,
    "gpp_weapon_firerate" => :rate_of_fire,
    "gpp_armor_radiationdissipation" => :radiation_scrub_rate
  }.freeze

  COMPONENT = {
    "gpp_itemresource_coolantgeneration" => "cooling_rate",
    "gpp_shield_maxhealth" => "max_health",
    "gpp_radar_minaimassistdistance" => "aim_assist_min",
    "gpp_radar_maxaimassistdistance" => "aim_assist_range",
    "gpp_quantum_speed" => "drive_speed",
    "gpp_weapon_tractor_force" => "max_force",
    "gpp_weapon_tractor_maxdist" => "max_distance",
    "gpp_weapon_tractor_maxvolume" => "max_volume"
  }.freeze

  # Armour states its band as one rendered string rather than as two columns.
  # 15 of the 850 omit the degree sign, so it is optional here.
  TEMPERATURE = /\A\s*(-?[\d.]+)\s*\/\s*(-?[\d.]+)\s*°?\s*C\s*\z/

  # A weapon's damage is split across the types it deals, almost always with
  # one of them carrying the whole figure.
  DAMAGE_TYPES = %w[physical energy thermal distortion biochemical stun].freeze

  def initialize(craftable)
    @craftable = craftable
  end

  # @return [Float, nil] what the modifier's factor applies to, or nil where
  #   the catalogue holds no such figure for this item.
  def for(property_key)
    return if craftable.blank?

    case craftable
    when Equipment then equipment_value(property_key)
    when Component then component_value(property_key)
    end
  end

  private

  attr_reader :craftable

  def equipment_value(property_key)
    return temperature(property_key) if property_key.start_with?("gpp_armor_temperature")

    field = EQUIPMENT[property_key]
    return if field.blank?

    numeric(craftable.public_send(field))
  end

  def temperature(property_key)
    match = TEMPERATURE.match(craftable.temperature_rating.to_s)
    return if match.blank?

    match[property_key.end_with?("min") ? 1 : 2].to_f
  end

  def component_value(property_key)
    data = craftable.type_data
    return if data.blank?

    return damage(data) if property_key == "gpp_weapon_damage"

    field = COMPONENT[property_key]
    return if field.blank?

    numeric(data[field])
  end

  def damage(data)
    per_shot = data["damage_per_shot"]
    return if per_shot.blank?

    total = DAMAGE_TYPES.sum { |type| per_shot[type].to_f }
    total.zero? ? nil : total
  end

  def numeric(value)
    return if value.blank?
    return if value.is_a?(Hash) || value.is_a?(Array)

    Float(value, exception: false)
  end
end
