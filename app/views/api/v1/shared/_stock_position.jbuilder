# frozen_string_literal: true

json.id position.position_id
json.slug position.slug
json.name position.name
json.category position.category
json.unit position.unit
if position.respond_to?(:quality_min)
  json.quality_min position.quality_min
  json.quality_max position.quality_max
else
  json.quality position.quality
end
json.net_quantity position.net_quantity.to_f

# The catalogue record the position's entries point at, where they agree on
# one. The name is left to the detail endpoint: the position carries its own,
# and this is here so a caller can match a position to a record by id rather
# than by guessing at a user-typed name. The slug is what a row links with.
if position.respond_to?(:item_id) && position.item_id.present?
  json.item do
    json.id position.item_id
    json.type position.item_type
    linked = local_assigns.fetch(:linked_items, {})[[position.item_type, position.item_id]]
    json.slug linked&.slug
    json.listed linked.try(:listed?) != false
  end
else
  json.item nil
end

if position.respond_to?(:inventory_name) && position.inventory_name.present?
  json.inventory do
    json.name position.inventory_name
    json.slug position.inventory_slug

    # Present where the inventory is a ship's rather than one made by hand.
    if position.respond_to?(:vehicle_name) && position.vehicle_name.present?
      json.vehicle_name position.vehicle_name
    end
  end
end
