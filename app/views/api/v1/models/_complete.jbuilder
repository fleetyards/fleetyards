# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.manufacturer do
    json.partial! 'api/v1/models/manufacturer', manufacturer: model.manufacturer if model.manufacturer.present?
  end
  json.hardpoints do
    json.array! model.hardpoints, partial: 'api/v1/models/hardpoint', as: :hardpoint
  end
  json.images do
    json.array! model.images, partial: 'api/v1/images/base', as: :image
  end
  json.videos do
    json.array! model.videos, partial: 'api/v1/models/video', as: :video
  end
  json.partial! 'api/shared/dates', record: model
end
