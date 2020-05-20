# frozen_string_literal: true

json.name vehicle.export_name
json.slug vehicle.model_paint&.slug || vehicle.model.slug
json.custom_name vehicle.name
json.purchased vehicle.purchased
json.flagship vehicle.flagship
json.public vehicle.public
json.name_visible vehicle.name_visible
json.sale_notify vehicle.sale_notify
json.groups vehicle.hangar_groups.map(&:name)
json.modules vehicle.model_modules.map(&:name)
json.upgrades vehicle.model_upgrades.map(&:name)
