# frozen_string_literal: true

json.id fleet.id
json.name fleet.name
json.slug fleet.slug
json.logo((fleet.logo.small.url if fleet.logo.present?))
json.background_image((fleet.background_image.url if fleet.background_image.present?))