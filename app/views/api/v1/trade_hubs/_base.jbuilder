# frozen_string_literal: true

json.cache! ['v1', trade_hub] do
  json.id trade_hub.id
  json.name trade_hub.name
  json.slug trade_hub.slug
  json.planet trade_hub.planet
  json.system trade_hub.system
  json.type trade_hub.station_type
  json.trade_commodities do
    json.array! trade_hub.trade_commodities.include(:commodity).order("commodities.name ASC"), partial: 'api/v1/trade_hubs/trade_commodity', as: :trade_commodity
  end
  json.partial! 'api/shared/dates', record: trade_hub
end
