# frozen_string_literal: true

json.partial! "api/v1/commodities/commodity", commodity: @commodity

json.cache! ["v1", @commodity, ::ScData::Source.current, @commodity.item_prices_cache_key, :availability] do
  json.availability do
    json.bought_at do
      json.array! @commodity.bought_at, partial: "api/v1/item_prices/base", as: :item_price
    end
    json.sold_at do
      json.array! @commodity.sold_at, partial: "api/v1/item_prices/base", as: :item_price
    end
  end
end

# Outside the cached fragment: its key is this row, and a raw form retargeting
# its refinement changes only that other row.
json.refined_from @refined_from do |source|
  json.id source.id
  json.name source.name
  json.slug source.slug
end
