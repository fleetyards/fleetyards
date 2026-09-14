# frozen_string_literal: true

# One of the contract's two ends. A transport contract has both; the other two
# kinds have only a destination, and a deleted inventory nulls either of them.
json.set! name do
  if inventory.present?
    json.id inventory.id
    json.name inventory.name
    json.slug inventory.slug
    json.location inventory.location
  else
    json.null!
  end
end
