# frozen_string_literal: true

# What the export states. Which is reputation, items and badges -- and, for 8 of
# the 2536 contracts, a currency figure.
#
# There is deliberately no payout field for the other 2352. They award
# `ContractResult_CalculatedReward`, an empty element whose number the game
# computes at run time, and no table, curve or scalar anywhere in the export
# could reproduce it. A field empty on 99.7% of rows would read as our gap
# rather than as the game's.
json.rewards mission.facts&.rewards.to_a do |reward|
  json.kind reward.kind
  json.amount reward.amount
  json.max reward.max
  json.currency reward.currency

  # Whether the game sets the figure when it generates the mission. True for
  # 2352 of the contracts that pay; the 8 that state an amount are false.
  json.calculated reward.calculated?

  # Reputation only: whose standing moves, which is not always the org offering
  # the contract. A negative amount is a loss, and 16 of the 58 amounts the
  # export declares are negative.
  json.org_name reward.org_name
  json.org_key reward.org_key

  # Item only. The entity class is not resolved to a catalogue row: an award
  # names things that are variously equipment, a commodity crate, or a mission
  # carryable in no catalogue at all.
  json.entity_class reward.entity_class
  json.entity_name reward.entity_name
  json.weight reward.weight

  json.badge reward.badge
end
