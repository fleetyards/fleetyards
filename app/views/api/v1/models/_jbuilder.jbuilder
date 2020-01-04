# frozen_string_literal: true

json.partial! 'api/v1/models/base', model: model
json.hardpoints do
  json.array! model.hardpoints, partial: 'api/v1/models/hardpoint', as: :hardpoint
end
json.partial! 'api/shared/dates', record: model
