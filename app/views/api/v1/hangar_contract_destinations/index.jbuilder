# frozen_string_literal: true

json.array! @targets do |contract|
  json.contract_id contract.id
  json.contract_title contract.display_title
  json.contract_slug contract.slug
  json.fleet_slug contract.fleet.slug
  json.fleet_name contract.fleet.name
  json.destination do
    json.partial! "api/v1/fleet_contracts/destination", inventory: contract.destination
  end
end
