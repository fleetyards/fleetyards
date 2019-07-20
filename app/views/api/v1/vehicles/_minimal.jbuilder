# frozen_string_literal: true

json.id vehicle.id
json.name vehicle.name
json.purchased vehicle.purchased
json.flagship vehicle.flagship
json.public vehicle.public
json.name_visible vehicle.name_visible
json.sale_notify vehicle.sale_notify
json.model_slug vehicle.model_slug
json.model vehicle.model_name
json.manufacturer vehicle.model_manufacturer
json.store_image_medium vehicle.model.store_image.medium.url
json.partial! 'api/shared/dates', record: vehicle
