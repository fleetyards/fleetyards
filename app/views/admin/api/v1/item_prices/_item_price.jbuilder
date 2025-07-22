# frozen_string_literal: true

json.cache! ["v1", item_price, local_assigns.fetch(:extended, false)] do
  json.partial!("api/v1/item_prices/base", item_price:, extended: local_assigns.fetch(:extended, false))
end
