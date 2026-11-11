# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name_visible? ? vehicle.name : nil
if vehicle.model.present?
  json.model do
    json.id vehicle.model.id
    json.name vehicle.model.name
    json.slug vehicle.model.slug
    json.classification vehicle.model.classification
    json.foci vehicle.model.foci
    json.size vehicle.model.size
    json.crew vehicle.model.crew
    json.cargo vehicle.model.cargo
    json.partial! "api/v1/shared/ship_model_image", model: vehicle.model
  end
else
  json.model nil
end
