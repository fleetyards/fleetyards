# frozen_string_literal: true

# The referenced catalogue record is in the key because the payload carries
# its name, slug and whether it has a page: a rename or a hidden variant has to
# reach an entry nobody has touched since. v3 is `listed`, v4 the item's angled view standing in for a missing store image, v5 the angled view ahead of the store image.
# Its builds are in it too: a load writes those without touching the record.
item = fleet_inventory_item.item
json.cache! ["v5", fleet_inventory_item, item, item.try(:build), item.try(:facts)] do
  json.partial!("api/v1/fleet_inventory_items/base", fleet_inventory_item:)
end
