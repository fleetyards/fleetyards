# frozen_string_literal: true

json.dedication vehicle.dedication
json.dedication_verse vehicle.dedication_verse
json.launched_on vehicle.launched_on
json.launch_port vehicle.launch_port
json.partial! "api/v1/locations/linked", key: :launch_port_location, location: vehicle.launch_port_location
json.affiliation vehicle.affiliation
json.operations_group vehicle.operations_group
json.plaque_captain vehicle.plaque_captain
json.shipyard vehicle.model&.manufacturer&.shipyard
json.manufacturer_short_name vehicle.model&.manufacturer&.short_name
json.manufacturer_code vehicle.model&.manufacturer&.code
json.plaque_style vehicle.effective_plaque_style if vehicle.dedication.present?
json.plaque_locale vehicle.plaque_locale
