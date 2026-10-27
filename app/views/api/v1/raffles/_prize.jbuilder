# frozen_string_literal: true

json.id model.id
json.name model.name
json.slug model.slug
json.store_image do
  json.partial! "api/v1/shared/file", record: model, attr: model.display_image_attr || :store_image
end
