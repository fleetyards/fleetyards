# frozen_string_literal: true

json.key group.key
json.name group.name
if group.location
  json.location do
    json.partial! "api/v1/locations/link", location: group.location
  end
end
json.system_name group.system_name
json.item_ids group.lines.map { |line| line.cart_item.id }
json.subtotal group.subtotal.to_f
