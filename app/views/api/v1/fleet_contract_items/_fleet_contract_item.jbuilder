# frozen_string_literal: true

# The referenced catalogue record is in the key because the payload carries
# its name, slug and whether it has a page. v2 is `listed`.
json.cache! ["v2", fleet_contract_item, fleet_contract_item.item] do
  json.partial!("api/v1/fleet_contract_items/base", fleet_contract_item:)
end
