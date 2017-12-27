# frozen_string_literal: true

json.name trade_commodity.commodity.name
json.slug trade_commodity.commodity.slug
json.buy_price trade_commodity.buy_price.zero? ? nil : trade_commodity.buy_price
json.sell_price trade_commodity.sell_price.zero? ? nil : trade_commodity.sell_price
json.buy trade_commodity.buy
json.sell trade_commodity.sell
