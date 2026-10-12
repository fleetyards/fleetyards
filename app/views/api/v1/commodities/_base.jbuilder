# frozen_string_literal: true

json.id commodity.id
json.name commodity.name
json.slug commodity.slug
json.commodity_type commodity.commodity_type
json.description commodity.description
json.counted commodity.counted?
json.piece_volume commodity.piece_volume&.to_f
json.consumable commodity.consumable?
json.container_sizes commodity.container_sizes.map(&:to_f)

if commodity.refines_into.present?
  json.refines_into do
    json.id commodity.refines_into.id
    json.name commodity.refines_into.name
    json.slug commodity.refines_into.slug
  end
else
  json.refines_into nil
end
json.retired commodity.retired?

json.store_image do
  json.partial! "api/v1/shared/file", record: commodity, attr: :store_image
end

# The cheapest of each direction across every terminal, which is what the row
# and the price sorts both read. The per-terminal rows behind them -- 539 on a
# page of 60 -- are only on the detail.
json.buy_price commodity.buy_price&.to_f
json.sell_price commodity.sell_price&.to_f

json.partial! "api/shared/dates", record: commodity
