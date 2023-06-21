# frozen_string_literal: true

json.partial!("api/v1/hangar_groups/base", group:)
json.public group.public
json.sort group.sort
json.vehiclesCount group.vehicles.count
json.partial! "api/shared/dates", record: group
