# frozen_string_literal: true

json.items do
  json.array!(@fleet_contracts) do |fleet_contract|
    json.partial! "api/v1/fleet_contracts/fleet_contract",
      fleet_contract: fleet_contract,
      progress: @progress_by_id.fetch(fleet_contract.id)
  end
end
json.partial! "api/shared/meta", result: @fleet_contracts
