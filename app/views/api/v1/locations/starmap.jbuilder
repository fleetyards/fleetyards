# frozen_string_literal: true

json.system do
  json.partial! "api/v1/locations/link", location: @starmap.system
end

# The images of the build being shown: live's or PTU's.
environment = ::Location.served_source.environment

json.places @places do |place|
  location = place.location

  json.partial! "api/v1/locations/link", location: location
  json.parent_id location.parent_id
  json.position place.position
  json.radius place.radius
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

  ::LocationSurface::ROLES.each do |role|
    image = location.starmap_image(role, environment)

    if image
      json.set! role do
        json.partial! "api/v1/shared/file", record: image.record, attr: role
      end
    else
      json.set! role, nil
    end
  end
end
