# frozen_string_literal: true

json.items @models do |model|
  json.partial! "api/v1/filters/models/option",
    model: model,
    owned_model_ids: @owned_model_ids,
    wanted_model_ids: @wanted_model_ids
end
json.partial! "api/shared/meta", result: @models
