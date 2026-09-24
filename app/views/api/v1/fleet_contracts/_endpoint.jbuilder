# frozen_string_literal: true

# One of the contract's two ends. A transport contract has both; the other two
# kinds have only a destination, and a deleted inventory nulls either of them.
json.set! name do
  if inventory.present?
    json.partial! "api/v1/fleet_contracts/destination", inventory: inventory
  else
    json.null!
  end
end
