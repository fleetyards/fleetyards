# frozen_string_literal: true

# The cost tree and where the recipe comes from. Rendered by the public detail
# response and by the admin one, which shows the same recipe.

# Built once for the whole recipe rather than per modifier: every slot's stats
# resolve against the same crafted item.
stat_bases = BlueprintStatBases.new(blueprint.craftable)

# The recipe, which a list leaves out rather than paying three association hits
# per row for.
json.cost_slots blueprint.cost_slots do |slot|
  json.name slot.name
  json.sc_key slot.sc_key
  json.position slot.position

  # Every slot in the current build accepts exactly one material, but the game
  # files allow several and already carry the string for it, so this stays an
  # array rather than collapsing to a single option.
  json.options slot.options do |option|
    json.type option.cost_type
    json.quantity option.quantity
    json.min_quality option.min_quality

    # The material, and what we know it as. `commodityKey` answers even where
    # the catalogue has no row, so a cost line never renders nameless.
    json.commodity_key option.commodity_key

    if option.commodity.present?
      json.commodity do
        json.id option.commodity.id
        json.name option.commodity.name
        json.slug option.commodity.slug
      end
    end
  end

  # What filling the slot with better material buys. A stat can ramp piecewise,
  # so one stat may appear more than once with different quality windows.
  json.modifiers slot.modifiers do |modifier|
    json.name modifier.name
    json.property_key modifier.property_key
    json.unit_format modifier.unit_format
    json.ramp modifier.ramp
    json.start_quality modifier.start_quality
    json.end_quality modifier.end_quality
    # `to_f`, as every other decimal here: a BigDecimal renders as a JSON
    # string, which the schema does not say and the client cannot compute on.
    json.modifier_at_start modifier.modifier_at_start&.to_f
    json.modifier_at_end modifier.modifier_at_end&.to_f

    json.unit modifier.unit
    json.base_value stat_bases.for(modifier.property_key)
  end
end

# Where it comes from. Empty for the 901 the export says nothing about, which
# `sourceUnknown` states outright.
json.sources blueprint.sources do |source|
  json.kind source.kind
  json.org_name source.org_name
  json.mission_name source.mission_name
  json.min_standing source.min_standing
  json.max_standing source.max_standing
  json.min_points source.min_points
  json.pool_key source.pool_key
  json.pool_group source.pool_group
end
