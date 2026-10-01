# frozen_string_literal: true

json.items @matches do |match|
  json.token match.token
  json.name match.name
  json.type match.type
  json.slug match.slug
  json.fleet_slug match.fleet_slug if match.fleet_slug
end
