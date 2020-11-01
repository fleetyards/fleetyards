# frozen_string_literal: true

json.name shop_commodity.commodity_item.name
json.slug shop_commodity.commodity_item.slug
json.store_image shop_commodity.commodity_item.store_image.url
json.store_image_medium shop_commodity.commodity_item.store_image.medium.url
json.store_image_small shop_commodity.commodity_item.store_image.small.url
json.category shop_commodity.category
json.sub_category shop_commodity.sub_category
json.sub_category_label shop_commodity.sub_category_label
json.description shop_commodity.commodity_item.description
json.price_per_unit shop_commodity.price_per_unit
json.sell_price shop_commodity.sell_price
json.buy_price shop_commodity.buy_price
json.rental_price_1_day shop_commodity.rental_price_1_day
json.rental_price_3_days shop_commodity.rental_price_3_days
json.rental_price_7_days shop_commodity.rental_price_7_days
json.rental_price_30_days shop_commodity.rental_price_30_days
json.location_label shop_commodity.location_label
json.shop do
  json.partial! 'api/v1/shops/base', shop: shop_commodity.shop
end
json.item do
  json.partial! "api/v1/#{shop_commodity.category.pluralize}/minimal", shop_commodity.category.to_sym => shop_commodity.commodity_item
end
