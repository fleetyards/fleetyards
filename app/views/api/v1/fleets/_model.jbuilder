# frozen_string_literal: true

json.cache! ['v1', model, @fleet.model_usernames(model.id).join('_')] do
  json.usernames @fleet.model_usernames(model.id)
  json.count @fleet.model_count(model.id)
  json.partial! 'api/v1/models/base', model: model
  json.partial! 'api/shared/dates', record: model
end
