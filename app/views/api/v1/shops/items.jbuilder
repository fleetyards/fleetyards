# frozen_string_literal: true

json.items @items do |row|
  item = row.item

  json.id item.id
  json.item_type item.class.name
  json.name item.name
  json.slug item.slug
  json.category_id row.category_id
  json.category_label row.category_label

  manufacturer = item.try(:manufacturer)
  if manufacturer
    json.manufacturer do
      json.name manufacturer.name
      json.slug manufacturer.slug
    end
  else
    json.manufacturer nil
  end

  json.buy_price row.buy_price&.to_f
  json.rental_price row.rental_price&.to_f
  json.rental_time_range row.rental_time_range
  json.sell_price row.sell_price&.to_f
end

json.partial! "api/shared/meta", result: @items
