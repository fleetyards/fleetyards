# frozen_string_literal: true

json.id fleet_contract.id
json.title fleet_contract.title
json.slug fleet_contract.slug
json.description fleet_contract.description
json.kind fleet_contract.kind
json.state fleet_contract.aasm_state
json.reward fleet_contract.reward
json.reimburse_expenses fleet_contract.reimburse_expenses
json.crew_limit fleet_contract.crew_limit
json.requires_pickup fleet_contract.requires_pickup?
json.deadline fleet_contract.deadline&.utc&.iso8601

json.partial! "api/v1/fleet_contracts/endpoint",
  inventory: fleet_contract.source_fleet_inventory, name: :source
json.partial! "api/v1/fleet_contracts/endpoint",
  inventory: fleet_contract.destination_fleet_inventory, name: :destination

if fleet_contract.created_by.present?
  json.created_by do
    json.id fleet_contract.created_by.id
    json.username fleet_contract.created_by.username
  end
else
  json.created_by nil
end

json.published_at fleet_contract.published_at&.utc&.iso8601
json.claimed_at fleet_contract.claimed_at&.utc&.iso8601
json.fulfilled_at fleet_contract.fulfilled_at&.utc&.iso8601
json.cancelled_at fleet_contract.cancelled_at&.utc&.iso8601
json.expired_at fleet_contract.expired_at&.utc&.iso8601

json.partial! "api/shared/dates", record: fleet_contract
