# frozen_string_literal: true

json.array! @destinations do |inventory|
  json.partial! "api/v1/fleet_contracts/destination", inventory: inventory
end
