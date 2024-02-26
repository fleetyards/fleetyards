# frozen_string_literal: true

json.items do
  json.array! @celestial_objects, partial: "api/v1/celestial_objects/celestial_object", as: :celestial_object
end
json.partial! "api/shared/meta", result: @celestial_objects
