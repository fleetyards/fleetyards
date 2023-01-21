# frozen_string_literal: true

json.partial! "api/v2/hangar/groups/base", group: hangar_group
json.sort group.sort
json.vehiclesCount group.vehicles.count
