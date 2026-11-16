# frozen_string_literal: true

json.id door["id"]
json.kind door["kind"]
json.position door["position"]
json.duration_s door["duration_s"]
json.exterior door["exterior"] == true

if (bounds = door["obb_closed"])
  json.bounds do
    json.center bounds["center"]
    json.axes bounds["axes"]
    json.half_size bounds["half_size"]
  end
else
  json.bounds nil
end

if (outline = door["outline"])
  json.outline do
    json.center outline["center"]
    json.axes outline["axes"]
    json.half_size outline["half_size"]
  end
else
  json.outline nil
end
json.outline_nodes door["outlineNodes"] || []

json.parts(door["parts"].each_with_index.to_a) do |(part, index)|
  json.part index
  json.object part["object"]
  json.keyframes(part.dig("motion", "keyframes")) do |keyframe|
    json.t keyframe["t"]
    json.translation keyframe["translation"]
    json.rotation keyframe["rotation"]
  end
end
