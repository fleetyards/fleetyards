# frozen_string_literal: true

json.cache! ['v1', result] do
  json.id result.id
  json.partial! "api/v1/search/#{result.class.name.underscore}", result: result
  json.partial! 'api/shared/dates', record: result
end
