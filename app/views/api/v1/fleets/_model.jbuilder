# frozen_string_literal: true

json.cache! ['v1', model, @fleet.vehicles(model_id: model.id).map(&:id).join('_')] do
  json.vehicles do
    json.array! @fleet.vehicles(model_id: model.id), partial: 'api/v1/vehicles/minimal_public', as: :vehicle
  end
  json.partial! 'api/v1/models/base', model: model
  json.partial! 'api/shared/dates', record: model
end
