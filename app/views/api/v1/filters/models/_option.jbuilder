# frozen_string_literal: true

json.cache! ["v1/filters/models/option", model] do
  json.id model.id
  json.name model.name
  json.slug model.slug

  json.media do
    json.store_image do
      json.partial! "api/v1/shared/file", record: model, attr: :store_image
    end
  end
end
