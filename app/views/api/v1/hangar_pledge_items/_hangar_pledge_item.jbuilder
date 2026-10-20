# frozen_string_literal: true

json.id hangar_pledge_item.id
json.rsi_pledge_id hangar_pledge_item.rsi_pledge_id
json.rsi_page hangar_pledge_item.rsi_page if hangar_pledge_item.rsi_page.present?
json.kind hangar_pledge_item.kind
json.name hangar_pledge_item.name
json.quantity hangar_pledge_item.quantity
json.image hangar_pledge_item.image_url if hangar_pledge_item.image_url.present?
json.standalone hangar_pledge_item.standalone?
json.meltable hangar_pledge_item.meltable
json.pledge_created_on hangar_pledge_item.pledge_created_on.iso8601 if hangar_pledge_item.pledge_created_on.present?
json.melt_value hangar_pledge_item.melt_value.to_f unless hangar_pledge_item.melt_value.nil?
json.pledge_name hangar_pledge_item.pledge_name if hangar_pledge_item.pledge_name.present?
json.pledge_value hangar_pledge_item.pledge_value.to_f unless hangar_pledge_item.pledge_value.nil?

# What the item is in the catalogue, where the sync matched one: what an
# inventory entry made from it refers to.
catalogued = hangar_pledge_item.catalogue_component || hangar_pledge_item.catalogue_equipment
if catalogued.present?
  json.catalogue_item do
    json.item_type catalogued.class.name
    json.id catalogued.id
    json.name catalogued.name
    category = catalogued.is_a?(Component) ? catalogued.category : catalogued.equipment_type
    json.slug catalogued.slug if catalogued.slug.present?
    json.category category if category.present?
    json.size catalogued.size if catalogued.size.present?
    json.listed catalogued.is_a?(Component) ? catalogued.catalogued? : catalogued.listed?
  end
end

# The inventory the item was added to, so a list can say where it went.
inventory = local_assigns[:deposits]&.dig(hangar_pledge_item.source_key)&.inventory
if inventory.present?
  json.inventory do
    json.name inventory.name
    json.slug inventory.slug
  end
end

json.partial! "api/shared/dates", record: hangar_pledge_item
