# frozen_string_literal: true

json.id result.id
json.type result.class.name
json.item do
  case result.class.name
  when "Model"
    json.partial! "api/v1/models/base", model: result
  when "ShopCommodity"
    json.partial! "api/v1/shop_commodities/base", shop_commodity: result
  when "Shop"
    json.partial! "api/v1/shops/base", shop: result
  when "Component"
    json.partial! "api/v1/components/base", component: result
  when "Commodity"
    json.partial! "api/v1/commodities/base", commodity: result
  when "Equipment"
    json.partial! "api/v1/equipment/base", equipment: result
  when "Station"
    json.partial! "api/v1/stations/base", station: result
  when "CelestialObject"
    json.partial! "api/v1/celestial_objects/base", celestial_object: result
  when "Starsystem"
    json.partial! "api/v1/starsystems/base", starsystem: result
  end
end
