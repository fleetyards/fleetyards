# frozen_string_literal: true

json.cache! ["v2", model] do
  json.name "#{model.manufacturer.code} #{model.name}"
  json.value model.slug
  json.cargo model.cargo
end
