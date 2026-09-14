# frozen_string_literal: true

json.cache! ["v1", fleet_contract_item] do
  json.partial!("api/v1/fleet_contract_items/base", fleet_contract_item:)
end
