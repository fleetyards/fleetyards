# frozen_string_literal: true

if @model.holo_hull.attached?
  json.holo_hull do
    json.partial! "api/v1/shared/file", record: @model, attr: :holo_hull
  end
end

json.ports(@model.hardpoint_transforms&.fetch("ports", []) || []) do |port|
  json.name port["name"]
  json.parent port["parent"]
  json.helper port.fetch("helper", true)
  json.position port["position"]
  json.rotation port["rotation"]
  json.flags port["flags"].to_s
  json.editable port["editable"] == true
  json.types(port["types"] || []) do |type|
    json.type type["type"]
    json.sub_types type["subTypes"].to_s
  end
  json.default_item port["defaultItem"]
  json.geometry port.fetch("geometry", true)
  json.stripped port["stripped"] == true
end
