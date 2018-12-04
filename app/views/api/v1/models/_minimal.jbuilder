# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.manufacturer do
    json.manufacturer nil if model.manufacturer.blank?
    json.partial! 'api/v1/manufacturers/base', manufacturer: model.manufacturer if model.manufacturer.present?
  end
  json.partial! 'api/shared/dates', record: model
end
