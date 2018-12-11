# frozen_string_literal: true

json.cache! ['v1', commodity] do
  json.partial! 'api/v1/commodities/base', commodity: commodity
  json.partial! 'api/shared/dates', record: commodity
end
