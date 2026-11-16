# frozen_string_literal: true

json.name port["name"]
json.parent port["parent"]
json.helper port["helper"] != false
json.position port["position"]
json.rotation port["rotation"]
json.flags port["flags"].to_s
json.editable port["editable"] == true
json.types(port["types"] || []) do |type|
  json.type type["type"]
  json.sub_types type["subTypes"].to_s
end
json.default_item port["defaultItem"]
json.geometry port["geometry"] != false
json.stripped port["stripped"] == true
json.in_parent_holo port["inParentHolo"] == true
json.hull_node port["hullNode"]
built_in = built_in_items[port["defaultItem"]] if port["hullNode"]
json.default_item_name built_in&.name
json.default_item_slug built_in&.slug
json.item_kind port["itemKind"] && (V1::Schemas::Enums::HullItemKindEnum::VALUES.include?(port["itemKind"]) ? port["itemKind"] : "other")
