# frozen_string_literal: true

json.id fleet_contract_assignment.id
json.role fleet_contract_assignment.role
json.state fleet_contract_assignment.aasm_state

if fleet_contract_assignment.user.present?
  json.user do
    json.id fleet_contract_assignment.user.id
    json.username fleet_contract_assignment.user.username
    json.avatar do
      json.partial! "api/v1/shared/file", record: fleet_contract_assignment.user, attr: :avatar
    end
  end
else
  json.user nil
end

json.requested_at fleet_contract_assignment.requested_at&.utc&.iso8601
json.accepted_at fleet_contract_assignment.accepted_at&.utc&.iso8601

json.partial! "api/shared/dates", record: fleet_contract_assignment
