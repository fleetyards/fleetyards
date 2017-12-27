# frozen_string_literal: true

json.cache! ['v1', commodity] do
  json.id commodity.id
  json.name commodity.name
  json.slug commodity.slug
  json.partial! 'api/shared/dates', record: commodity
end
