# frozen_string_literal: true

json.cache! ['v1', station] do
  json.name station.name
  json.value station.id
  json.category 'Station'
end
