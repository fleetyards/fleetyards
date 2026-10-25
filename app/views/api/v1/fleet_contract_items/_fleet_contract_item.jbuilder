# frozen_string_literal: true

# The referenced catalogue record is in the key because the payload carries
# its name, slug and whether it has a page. v2 is `listed`, v3 `rewardRate`.
# Its builds are in it too: a load writes those without touching the record.
item = fleet_contract_item.item
json.cache! ["v3", fleet_contract_item, item, item.try(:build), item.try(:facts)] do
  json.partial!("api/v1/fleet_contract_items/base", fleet_contract_item:)
end
