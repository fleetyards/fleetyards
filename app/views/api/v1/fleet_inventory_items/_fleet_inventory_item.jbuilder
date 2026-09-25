# frozen_string_literal: true

# The referenced catalogue record is in the key because the payload carries
# its name, slug and whether it has a page: a rename or a hidden variant has to
# reach an entry nobody has touched since. v3 is `listed`.
json.cache! ["v3", fleet_inventory_item, fleet_inventory_item.item] do
  json.partial!("api/v1/fleet_inventory_items/base", fleet_inventory_item:)
end
