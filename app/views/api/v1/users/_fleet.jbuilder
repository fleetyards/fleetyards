# frozen_string_literal: true

json.id fleet.id
json.fid fleet.fid
json.name fleet.name
json.slug fleet.slug
json.logo((fleet.logo.small.url if fleet.logo.present?))
json.background_image((fleet.background_image.url if fleet.background_image.present?))
json.role fleet.role(current_user&.id)
json.invitation fleet.invitation(current_user&.id)
json.accepted_at fleet.accepted_at(current_user&.id)&.utc&.iso8601
json.primary fleet.primary(current_user&.id)
json.hide_ships fleet.hide_ships(current_user&.id)
