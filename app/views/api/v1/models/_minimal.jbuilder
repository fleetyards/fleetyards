# frozen_string_literal: true

json.cache! ['v1', model] do
  json.partial! 'api/v1/models/base', model: model
  json.manufacturer do
    json.partial! 'api/v1/models/manufacturer', manufacturer: model.manufacturer if model.manufacturer.present?
  end
  json.manufacturer nil if model.manufacturer.blank?
  json.partial! 'api/shared/dates', record: model
end
