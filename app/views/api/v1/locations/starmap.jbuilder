# frozen_string_literal: true

json.system do
  json.partial! "api/v1/locations/link", location: @starmap.system
end

json.places @places do |place|
  location = place.location

  json.partial! "api/v1/locations/link", location: location
  json.parent_id location.parent_id
  json.position location.position
  json.radius location.radius
  json.shown_on_starmap location.shown_on_starmap
  json.shown_with_parent_only location.shown_with_parent_only
  json.always_shown location.always_shown
  json.quantum_travel_destination location.quantum_travel_destination
  json.lagrange_point place.lagrange_point
  json.gateway place.gateway
  json.color location.drawn_color
  json.unstable location.flare_star?
  json.body_type location.body_type
end
