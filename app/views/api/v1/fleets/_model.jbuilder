# frozen_string_literal: true

json.cache! ['v1', model, @fleet.model_users(model.id).map(&:username).join('_')] do
  json.users do
    json.array! @fleet.model_users(model.id), partial: 'api/v1/users/public', as: :user
  end
  json.count @fleet.model_count(model.id)
  json.partial! 'api/v1/models/base', model: model
  json.partial! 'api/shared/dates', record: model
end
