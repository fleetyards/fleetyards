# frozen_string_literal: true

json.id shop_commodity.id
json.name shop_commodity.commodity_item.name
json.slug shop_commodity.commodity_item.slug

json.category shop_commodity.category
json.commodity_item_id shop_commodity.commodity_item_id
json.commodity_item_type shop_commodity.commodity_item_type
json.confirmed shop_commodity.confirmed
json.description shop_commodity.commodity_item.description
json.location_label shop_commodity.location_label

json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: shop_commodity.commodity_item.store_image
  end
end

json.prices do
  json.average_buy_price shop_commodity.average_buy_price&.to_f
  json.average_rental_price_1_day shop_commodity.average_rental_price_1_day&.to_f
  json.average_rental_price_30_days shop_commodity.average_rental_price_30_days&.to_f
  json.average_rental_price_3_days shop_commodity.average_rental_price_3_days&.to_f
  json.average_rental_price_7_days shop_commodity.average_rental_price_7_days&.to_f
  json.average_sell_price shop_commodity.average_sell_price&.to_f
  json.buy_price shop_commodity.buy_price&.to_f
  json.rental_price_1_day shop_commodity.rental_price_1_day&.to_f
  json.rental_price_30_days shop_commodity.rental_price_30_days&.to_f
  json.rental_price_3_days shop_commodity.rental_price_3_days&.to_f
  json.rental_price_7_days shop_commodity.rental_price_7_days&.to_f
  json.sell_price shop_commodity.sell_price&.to_f
  json.price_per_unit shop_commodity.price_per_unit
end

json.shop do
  json.partial! "api/v1/shops/base", shop: shop_commodity.shop
end

json.sub_category shop_commodity.sub_category
json.sub_category_label shop_commodity.sub_category_label

json.store_image shop_commodity.commodity_item.store_image.url
json.store_image_large shop_commodity.commodity_item.store_image.large.url
json.store_image_medium shop_commodity.commodity_item.store_image.medium.url
json.store_image_small shop_commodity.commodity_item.store_image.small.url
