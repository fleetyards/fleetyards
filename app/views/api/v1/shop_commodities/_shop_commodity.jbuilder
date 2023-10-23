# frozen_string_literal: true

json.cache! ["v1", shop_commodity, shop_commodity.commodity_item, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/shop_commodities/base", shop_commodity:, extended: local_assigns.fetch(:extended, false))
end
