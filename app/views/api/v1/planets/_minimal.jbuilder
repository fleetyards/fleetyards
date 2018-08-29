# frozen_string_literal: true

json.cache! ['v1', planet] do
  json.partial! 'api/v1/planets/base', planet: planet
  json.partial! 'api/shared/dates', record: planet
end
