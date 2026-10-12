# frozen_string_literal: true

json.dedication vehicle.dedication
json.launched_on vehicle.launched_on
json.launch_port vehicle.launch_port
json.partial! "api/v1/locations/linked", key: :launch_port_location, location: vehicle.launch_port_location
json.affiliation vehicle.affiliation
json.shipyard vehicle.model&.manufacturer&.shipyard
