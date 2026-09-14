# frozen_string_literal: true

json.array! @fleet_contract_assignments,
  partial: "api/v1/fleet_contract_assignments/fleet_contract_assignment",
  as: :fleet_contract_assignment
