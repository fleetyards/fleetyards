# frozen_string_literal: true

if @model.holo_hull.attached?
  json.holo_hull do
    json.partial! "api/v1/shared/file", record: @model, attr: :holo_hull
  end
end

json.ports(@ports) do |port|
  json.partial! "api/v1/models/loadout_preview/port", port:, built_in_items: @built_in_items
end

json.items(@item_holos) do |component|
  json.sc_key component.sc_key
  json.holo_url rails_blob_url(component.holo)
end

# The modules that fit this ship's slots, drawn by their own hull: the parts on
# a module's ports, its cargo grids and its doors are its own, in its frame.
json.module_hulls(@module_hulls) do |component|
  export = component.hardpoint_transforms || {}

  json.sc_key component.sc_key.downcase
  json.holo_hull_url rails_blob_url(component.holo_hull)
  json.ports(export["ports"] || []) do |port|
    json.partial! "api/v1/models/loadout_preview/port", port:, built_in_items: @built_in_items
  end
  json.cargo_grids(export["cargo_grids"] || []) do |grid|
    json.partial! "api/v1/models/loadout_preview/cargo_grid", grid:
  end
  json.doors(component.holo_doors&.fetch("doors", nil) || []) do |door|
    json.partial! "api/v1/models/loadout_preview/door", door:
  end
end

json.servicing_areas(@servicing_areas) do |area|
  json.key area["key"]
  json.name area["label"]
  json.index area["index"]
  json.position area["position"]
  json.rotation area["rotation"]
  json.size area["size"]
  json.width area["width"]
  json.length area["length"]
  json.height area["height"]
end

json.cargo_grids(@cargo_grids) do |grid|
  json.partial! "api/v1/models/loadout_preview/cargo_grid", grid:
end

json.doors(@doors) do |door|
  json.partial! "api/v1/models/loadout_preview/door", door:
end
