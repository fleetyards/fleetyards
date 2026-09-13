# frozen_string_literal: true

json.cache! ["v1", fleet_contract] do
  json.partial!("api/v1/fleet_contracts/base", fleet_contract:)
end
