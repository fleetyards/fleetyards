# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.count @fleet.model_count(model.id)
  json.partial! 'api/shared/dates', record: model
end
