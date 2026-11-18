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
  # Whether a ship can dock or land there: a rest stop rather than a comm
  # array, which the map keeps in view the longest.
  json.docking Array.wrap(location.facilities&.dig("hangars")).any? || Array.wrap(location.facilities&.dig("pads")).any?

  {texture: :starmap_texture, elevation: :starmap_elevation, clouds: :starmap_clouds}.each do |key, attr|
    if location.public_send(attr).attached?
      json.set! key do
        json.partial! "api/v1/shared/file", record: location, attr:
      end
    else
      json.set! key, nil
    end
  end
end
