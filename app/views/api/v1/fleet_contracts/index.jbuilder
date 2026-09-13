# frozen_string_literal: true

json.items do
  json.array! @fleet_contracts, partial: "api/v1/fleet_contracts/fleet_contract", as: :fleet_contract
end
json.partial! "api/shared/meta", result: @fleet_contracts
