# frozen_string_literal: true

# The referenced catalogue record is in the key because the payload carries
# its name, slug and whether it has a page: a rename or a hidden variant has to
# reach an entry nobody has touched since. v3 is `listed`.
# Its builds are in it too: a load writes those without touching the record.
item = inventory_item.item
json.cache! ["v3", inventory_item, item, item.try(:build), item.try(:facts)] do
  json.partial!("api/v1/shared/inventory_item", inventory_item:)
end
