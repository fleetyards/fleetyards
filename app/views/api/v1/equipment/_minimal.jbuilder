# frozen_string_literal: true

json.cache! ['v1', equipment] do
  json.partial! 'api/v1/equipment/base', equipment: equipment
  json.manufacturer do
    json.null! if equipment.manufacturer.blank?
    json.partial! 'api/v1/shop_commodities/manufacturer', manufacturer: equipment.manufacturer if equipment.manufacturer.present?
  end
  json.partial! 'api/shared/dates', record: equipment
end
