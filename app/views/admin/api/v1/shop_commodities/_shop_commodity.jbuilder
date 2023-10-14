# frozen_string_literal: true

json.cache! ["v1", shop_commodity, local_assigns.fetch(:extended, false)] do
  json.partial!("admin/api/v1/shop_commodities/base", shop_commodity:, extended: local_assigns.fetch(:extended, false))
end
