# frozen_string_literal: true

json.cache! ["v1", fleet_contract_assignment] do
  json.partial!("api/v1/fleet_contract_assignments/base", fleet_contract_assignment:)
end
