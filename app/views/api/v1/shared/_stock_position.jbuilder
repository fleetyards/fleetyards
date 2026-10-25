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
linked = local_assigns.fetch(:linked_items, {})[[position.try(:item_type), position.try(:item_id)]]

if position.respond_to?(:item_id) && position.item_id.present?
  json.item do
    json.id position.item_id
    json.type position.item_type
    json.slug linked&.slug
    json.listed linked.try(:listed?) != false
  end
else
  json.item nil
end

# The record's picture, where the position names one. A position has no upload
# of its own: an entry's picture belongs to that entry.
if linked && (image_attr = InventoryLedgerEntry.item_image_attr(linked))
  json.image do
    json.partial! "api/v1/shared/file", record: linked, attr: image_attr
  end
end

# A crafted lot, where the row is one: `current_stock` holds crafted parts
# apart, `stock_positions` rolls every lot of a position into one row.
if position.respond_to?(:has_attribute?) && position.has_attribute?(:crafted_blueprint_id)
  blueprint = local_assigns.fetch(:crafted_blueprints, {})[position.crafted_blueprint_id]

  json.partial! "api/v1/shared/inventory_crafted", blueprint:, qualities: position.crafted_qualities
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
