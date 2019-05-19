# frozen_string_literal: true

json.cache! ['v1', model] do
  json.name model.name
  json.value model.id
  json.category 'Model'
end
