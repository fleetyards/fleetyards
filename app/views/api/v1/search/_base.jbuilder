# frozen_string_literal: true

json.id result.id
json.type result.class.name
json.item do
  case result.class.name
  when "Model"
    json.partial! "api/v1/models/base", model: result
  when "Component"
    json.partial! "api/v1/components/base", component: result
  end
end
