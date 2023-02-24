# frozen_string_literal: true

json.name vehicle.export_name
json.slug vehicle.model.slug
json.ship_code vehicle.model.sc_identifier
json.manufacturer_name vehicle.model.manufacturer.name
json.manufacturer_code vehicle.model.manufacturer.code
json.paint_slug vehicle.model_paint&.slug
json.ship_name vehicle.name
json.ship_serial vehicle.serial
json.purchased vehicle.purchased
json.flagship vehicle.flagship
json.public vehicle.public
json.name_visible vehicle.name_visible
json.sale_notify vehicle.sale_notify
json.groups vehicle.hangar_groups.map(&:name)
json.modules vehicle.model_modules.map(&:name)
json.upgrades vehicle.model_upgrades.map(&:name)
