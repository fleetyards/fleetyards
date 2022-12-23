# frozen_string_literal: true

json.cache! ['v2', model] do
  json.partial! 'api/v1/models/base', model: model
  json.partial! 'api/shared/dates', record: model
  json.partial! 'api/shared/record_links', record: model
end
