# frozen_string_literal: true

# Read out of the transfer ledger on every request -- never cached, and never
# stored. See `Contracts::Progress`.
json.complete progress.complete?
json.fraction progress.fraction.to_f

json.lines do
  json.array!(progress.lines) do |line|
    json.item_id line.item.id
    json.name line.item.name
    json.partial! "api/v1/fleet_contract_items/item_ref", fleet_contract_item: line.item
    json.category line.item.category
    json.unit line.item.unit
    json.quality line.item.quality
    json.quality_match line.item.quality_match
    json.requested line.requested
    json.delivered line.delivered
    json.picked_up line.picked_up
    json.remaining line.remaining
    json.complete line.complete?
    json.fraction line.fraction.to_f

    json.contributions do
      json.array!(line.contributions) do |contribution|
        json.user_id contribution.user_id
        json.delivered contribution.delivered
        json.weight contribution.weight.to_f
      end
    end
  end
end

# What the reward divides by when the contract settles. Derived here so a
# client never has to re-implement the rule.
json.shares do
  json.array!(progress.weights.to_a) do |user_id, weight|
    json.user_id user_id
    json.weight weight.to_f
    json.share progress.total_weight.zero? ? 0.0 : (weight / progress.total_weight).to_f
  end
end
