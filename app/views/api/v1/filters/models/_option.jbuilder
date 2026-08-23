# frozen_string_literal: true

json.cache! ["v1/filters/models/option", model] do
  json.id model.id
  json.name model.name
  json.slug model.slug

  json.manufacturer do
    json.name model.manufacturer&.name
    json.slug model.manufacturer&.slug
    json.code model.manufacturer&.code
  end

  json.classification model.classification
  json.classification_label model.classification&.humanize

  json.media do
    json.store_image do
      json.partial! "api/v1/shared/file", record: model, attr: :store_image
    end
  end
end

# Outside the fragment cache: both depend on who is asking, the cache key does not.
json.in_hangar owned_model_ids.include?(model.id)
json.on_wishlist wanted_model_ids.include?(model.id)
