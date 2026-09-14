# frozen_string_literal: true

json.partial! "api/v1/fleet_contracts/base", fleet_contract: @fleet_contract

json.items do
  json.array! @fleet_contract.fleet_contract_items.ordered,
    partial: "api/v1/fleet_contract_items/fleet_contract_item",
    as: :fleet_contract_item
end

json.crew do
  json.array! @fleet_contract.fleet_contract_assignments
    .where.not(aasm_state: %w[withdrawn removed declined]).includes(:user).order(:role, :created_at),
    partial: "api/v1/fleet_contract_assignments/fleet_contract_assignment",
    as: :fleet_contract_assignment
end

# Computed per request, so it renders outside every cache block.
json.progress do
  json.partial! "api/v1/fleet_contracts/progress", progress: @fleet_contract.progress
end
