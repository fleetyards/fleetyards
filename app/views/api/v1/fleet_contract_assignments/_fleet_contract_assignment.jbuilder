# frozen_string_literal: true

json.cache! ["v2", fleet_contract_assignment, fleet_contract_assignment.user&.avatar_cache_key] do
  json.partial!("api/v1/fleet_contract_assignments/base", fleet_contract_assignment:)
end
