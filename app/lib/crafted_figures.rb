# frozen_string_literal: true

# A crafted part's own figures: the catalogue's, moved by the recipe's
# modifiers at the material quality in each slot. The browser's
# `craftedComponent` (`craftedComponent.ts`, with the ramp in
# `useQualityRamp.ts`) does the same for the loadout page, so the stored
# firepower of a loadout with a crafted gun reads as the page does.
#
# The catalogue's figure is the neutral grade's, so a part crafted at 500 in
# every slot reads exactly as the catalogue's.
class CraftedFigures
  NEUTRAL_QUALITY = 500
  QUALITY_MIN = 0
  QUALITY_MAX = 1000

  # The part figure each crafted stat scales, by property key, as the
  # blueprint page reads its base values; a key with no figure in the catalogue
  # moves nothing.
  FIELDS = BlueprintStatBases::COMPONENT

  # A weapon's damage is split across the types it deals; the factor applies to
  # each of them alike.
  WEAPON_DAMAGE = "gpp_weapon_damage"

  ADDITIVE_RAMP = "linear_integer_additive"

  Change = Struct.new(:additive, :value)

  # `cost_slots` are a recipe build's slots with their modifiers, `qualities`
  # the grade per slot position, string-keyed as a loadout item stores them.
  def initialize(cost_slots, qualities)
    @cost_slots = cost_slots
    @qualities = qualities.to_h.transform_keys(&:to_s)
  end

  def type_data(type_data)
    crafted = type_data.to_h.deep_stringify_keys

    changes.each do |key, change|
      if key == WEAPON_DAMAGE
        per_shot = crafted["damage_per_shot"]
        crafted["damage_per_shot"] = per_shot.transform_values { |value| changed(value, change) } if per_shot.is_a?(Hash)
        next
      end

      field = FIELDS[key]
      crafted[field] = changed(crafted[field], change) if field && crafted.key?(field)
    end

    crafted
  end

  # Two slots moving one stat are independent factors on it and so multiply;
  # amounts add up.
  def changes
    @changes ||= @cost_slots.each_with_object({}) do |slot, changes|
      slot.modifiers.group_by { |modifier| modifier.property_key.presence || modifier.name.to_s }.each do |key, group|
        segments = segments_of(group)
        next if segments.empty?

        at = @qualities.fetch(slot.position.to_s, NEUTRAL_QUALITY)
        additive = group.first.ramp == ADDITIVE_RAMP
        held = changes[key]&.value

        changes[key] = Change.new(
          additive,
          additive ? (held || 0) + js_round(value_at(segments, at)) : (held || 1) * value_at(segments, at)
        )
      end
    end
  end

  # `Math.round`: halves go up, also below zero, where a crafted plant loses
  # pips.
  private def js_round(value)
    (value + 0.5).floor
  end

  private def changed(value, change)
    return value unless value.is_a?(Numeric)

    change.additive ? value + change.value : value * change.value
  end

  private def segments_of(modifiers)
    modifiers
      .reject { |modifier| modifier.modifier_at_start.nil? || modifier.modifier_at_end.nil? }
      .map do |modifier|
        {
          from: modifier.start_quality || QUALITY_MIN,
          to: modifier.end_quality || QUALITY_MAX,
          a: modifier.modifier_at_start.to_f,
          b: modifier.modifier_at_end.to_f
        }
      end
      .sort_by { |segment| segment[:from] }
  end

  # Outside its own domain a ramp holds its end value.
  private def value_at(segments, at)
    segments.each do |segment|
      next unless at <= segment[:to]

      span = segment[:to] - segment[:from]
      t = (span <= 0) ? 1 : (at - segment[:from]).fdiv(span)
      return segment[:a] + (segment[:b] - segment[:a]) * [t, 0].max
    end

    segments.last[:b]
  end
end
