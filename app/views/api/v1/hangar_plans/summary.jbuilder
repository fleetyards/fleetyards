# frozen_string_literal: true

json.totals do
  json.partial! "api/v1/hangar_plans/totals", summary: @summary
end

json.slots @summary.slot_costs do |cost|
  json.slot_id cost.slot_id
  json.state cost.state
  json.min_cost cost.min_cost.to_f
  json.max_cost cost.max_cost.to_f
  # Its low end comes from the owner's free ships, which a shared plan keeps private.
  json.store_cost_min((@public_view ? cost.store_cost : cost.store_cost_min)&.to_f)
  json.store_cost cost.store_cost&.to_f
  json.unresolved_count cost.unresolved_count
  json.complete cost.complete
end

json.issues @summary.issues do |issue|
  json.kind issue.kind
  json.name issue.name
  json.slot_id issue.slot_id
end

json.purchases @summary.purchases do |purchase|
  json.kind purchase.kind
  if purchase.from_model
    json.from_model do
      json.partial! "api/v1/hangar_plans/model", model: purchase.from_model
    end
  else
    json.from_model nil
  end
  if purchase.model
    json.model do
      json.partial! "api/v1/hangar_plans/model", model: purchase.model
    end
  else
    json.model nil
  end
  json.name purchase.name
  json.price purchase.price&.to_f
  json.quantity purchase.quantity
  json.token_count purchase.token_count
  json.slot_ids purchase.slot_ids
  json.not_on_sale purchase.not_on_sale
  # A buy-back's pledge id is the owner's, so a shared plan offers no cart.
  json.cart_items(@public_view ? [] : purchase.cart_items) do |item|
    json.kind item.kind
    json.sku_id item.sku_id
    json.from_ship_id item.from_ship_id
    json.to_ship_id item.to_ship_id
    json.to_sku_id item.to_sku_id
    json.pledge_id item.pledge_id
  end
end
