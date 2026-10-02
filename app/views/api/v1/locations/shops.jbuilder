# frozen_string_literal: true

json.shops @shops do |shop|
  json.name shop.name
  json.items_count shop.items.size

  json.items shop.items do |entry|
    json.id entry.item.id
    json.name entry.item.name
    json.slug entry.item.slug
    json.item_type entry.item.class.name

    json.prices entry.prices do |price|
      json.price_type price.price_type
      json.price price.price.to_f
      json.time_range price.time_range
    end
  end
end
