# frozen_string_literal: true

if @loadout_preview_enabled && @model.holo_hull.attached?
  json.holo_hull do
    json.partial! "api/v1/shared/file", record: @model, attr: :holo_hull
  end
end

json.ports(@ports) do |port|
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
  json.item_kind port["itemKind"] && (V1::Schemas::Enums::HullItemKindEnum::VALUES.include?(port["itemKind"]) ? port["itemKind"] : "other")
end

json.items(@item_holos) do |component|
  json.sc_key component.sc_key
  json.holo_url rails_blob_url(component.holo)
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
  json.name grid["name"]
  json.port grid["port"]
  json.parent_port grid["parentPort"]
  json.position grid["position"]
  json.rotation grid["rotation"]
  json.size grid["size"]
  json.scu grid["scu"]
  json.stripped grid["stripped"] == true
end

json.doors(@doors) do |door|
  json.id door["id"]
  json.kind door["kind"]
  json.position door["position"]
  json.duration_s door["duration_s"]

  if (bounds = door["obb_closed"])
    json.bounds do
      json.center bounds["center"]
      json.axes bounds["axes"]
      json.half_size bounds["half_size"]
    end
  else
    json.bounds nil
  end

  json.parts(door["parts"].each_with_index.to_a) do |(part, index)|
    json.part index
    json.object part["object"]
    json.keyframes(part.dig("motion", "keyframes")) do |keyframe|
      json.t keyframe["t"]
      json.translation keyframe["translation"]
      json.rotation keyframe["rotation"]
    end
  end
end
