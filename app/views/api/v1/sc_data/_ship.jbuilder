# frozen_string_literal: true

json.id model.id
json.name model.name
json.slug model.slug
json.manufacturer_name model.manufacturer&.name

if model.display_image_attr
  json.store_image do
    json.partial! "api/v1/shared/file", record: model, attr: model.display_image_attr
  end
end

preview = model.preview_view
if preview
  json.preview_image do
    json.partial! "api/v1/shared/file", record: model, attr: preview.name
  end
end
