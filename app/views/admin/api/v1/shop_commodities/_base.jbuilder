# frozen_string_literal: true

json.id shop_commodity.id
json.commodity_item_id shop_commodity.commodity_item_id
json.commodity_item_type shop_commodity.commodity_item_type
json.sell_price shop_commodity.sell_price
json.average_sell_price shop_commodity.average_sell_price
json.buy_price shop_commodity.buy_price
json.average_buy_price shop_commodity.average_buy_price
json.rental_price_1_day shop_commodity.rental_price_1_day
json.average_rental_price_1_day shop_commodity.average_rental_price_1_day
json.rental_price_3_days shop_commodity.rental_price_3_days
json.average_rental_price_3_days shop_commodity.average_rental_price_3_days
json.rental_price_7_days shop_commodity.rental_price_7_days
json.average_rental_price_7_days shop_commodity.average_rental_price_7_days
json.rental_price_30_days shop_commodity.rental_price_30_days
json.average_rental_price_30_days shop_commodity.average_rental_price_30_days
json.confirmed shop_commodity.confirmed
json.shop do
  json.partial! 'api/v1/shops/base', shop: shop_commodity.shop
end
json.item do
  json.partial! "admin/api/v1/#{shop_commodity.category.pluralize}/minimal", shop_commodity.category.to_sym => shop_commodity.commodity_item
end
