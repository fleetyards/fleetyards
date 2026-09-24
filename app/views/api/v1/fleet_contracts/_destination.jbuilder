# frozen_string_literal: true

# The name and place only. The author's own inventory is shown to every member
# who can see the contract, and nothing about what it holds belongs here.
json.id inventory.id
json.name inventory.name
json.slug inventory.slug
json.location inventory.location
json.holder inventory.is_a?(::FleetInventory) ? "fleet" : "user"
