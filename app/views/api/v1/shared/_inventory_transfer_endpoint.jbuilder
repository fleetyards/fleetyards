# frozen_string_literal: true

# An end of a transfer, reduced to what a reader needs to recognise it. Null
# when the far end has not been chosen yet, or when it was deleted after the
# transfer finished.
if inventory.blank?
  json.null!
else
  json.id inventory.id
  json.name inventory.name
  json.slug inventory.slug
  json.kind inventory.is_a?(::FleetInventory) ? "fleet" : "user"
end
