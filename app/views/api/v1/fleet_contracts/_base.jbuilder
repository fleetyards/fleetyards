# frozen_string_literal: true

json.id fleet_contract.id
# The stored title is an override; without one the contract describes itself
# from its goods. Clients render this and never have to know which it was.
json.title fleet_contract.display_title
json.custom_title fleet_contract.title
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

# Counted off the loaded associations rather than queried per row -- the index
# eager-loads both, so this is two queries for the page and not two per card.
# Who is on it, for a board that shows faces rather than a number. Capped: the
# crew list itself belongs to the contract's own page.
json.crew_preview do
  accepted = fleet_contract.fleet_contract_assignments
    .select { |assignment| assignment.aasm_state == "accepted" && assignment.user.present? }
    .sort_by(&:created_at)
    .first(4)

  json.array!(accepted) do |assignment|
    json.id assignment.user.id
    json.username assignment.user.username
    json.avatar do
      json.partial! "api/v1/shared/file", record: assignment.user, attr: :avatar
    end
  end
end

json.items_count fleet_contract.fleet_contract_items.size
json.crew_count fleet_contract.fleet_contract_assignments.count { |assignment| assignment.aasm_state == "accepted" }

json.partial! "api/shared/dates", record: fleet_contract
