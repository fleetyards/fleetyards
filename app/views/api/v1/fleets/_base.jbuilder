# frozen_string_literal: true

json.id fleet.id
json.name fleet.name
json.slug fleet.slug
json.logo((fleet.logo.small.url if fleet.logo.present?))
json.role fleet.role(current_user)
json.accepted fleet.accepted(current_user)
