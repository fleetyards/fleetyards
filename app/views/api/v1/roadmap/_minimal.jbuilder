# frozen_string_literal: true

json.cache! ['v1', item] do
  json.partial! 'api/v1/roadmap/base', item: item
  json.model do
    json.null! if item.model.blank?
    json.partial! 'api/v1/models/base', model: item.model if item.model.present?
  end
  json.partial! 'api/shared/dates', record: item
end
