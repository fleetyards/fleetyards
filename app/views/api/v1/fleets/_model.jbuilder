# frozen_string_literal: true

json.cache! ['v1', model, @fleet.vehicles(model_id: model.id, loaner: loaner_included?).map(&:id).join('_')] do
  json.vehicles do
    json.array! @fleet.vehicles(model_id: model.id, loaner: loaner_included?), partial: 'api/v1/vehicles/minimal_public', as: :vehicle
  end
  json.partial! 'api/v1/models/base', model: model
  json.partial! 'api/shared/dates', record: model
end
