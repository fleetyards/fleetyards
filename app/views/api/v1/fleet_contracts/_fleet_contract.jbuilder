# frozen_string_literal: true

json.cache! ["v1", fleet_contract] do
  json.partial!("api/v1/fleet_contracts/base", fleet_contract:)
end

# Read off the ledger on every request, so it renders outside the cache block.
# A board shows the bar, not the per-line detail the contract's own page does.
json.progress do
  summary = progress.summary

  json.fraction summary.fraction
  json.delivered summary.delivered
  json.requested summary.requested
  # Null when the lines are measured in different units, which is what tells a
  # client to show the share rather than a quantity.
  json.unit summary.unit
  json.complete summary.complete
end
