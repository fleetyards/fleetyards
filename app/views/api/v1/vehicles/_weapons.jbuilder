# frozen_string_literal: true

json.max_weapon_size stat&.max_weapon_size
# Largest first. jsonb keeps its keys in an order of its own.
json.weapon_sizes(stat&.weapon_sizes.to_h.map { |size, count| {size: size.to_i, count:} }&.sort_by { |entry| -entry[:size] })
json.alpha stat&.alpha
json.burst_dps stat&.burst_dps
json.sustained_dps_min stat&.sustained_dps_min
json.sustained_dps_max stat&.sustained_dps_max
