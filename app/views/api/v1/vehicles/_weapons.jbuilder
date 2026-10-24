# frozen_string_literal: true

json.max_weapon_size stat&.max_weapon_size
json.weapon_sizes(stat&.weapon_sizes.to_h.map { |size, count| {size: size.to_i, count:} })
