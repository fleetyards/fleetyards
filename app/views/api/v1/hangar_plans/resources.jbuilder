# frozen_string_literal: true

json.vehicles @resources.vehicles do |entry|
  json.id entry.vehicle.id
  json.name entry.vehicle.name
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: entry.vehicle.model
  end
  json.used_by entry.used_by
  json.meltable entry.vehicle.rsi_pledge_meltable
  json.melt_value entry.vehicle.rsi_pledge_melt_value&.to_f
  json.pledge_item_count entry.vehicle.rsi_pledge_item_count
end

json.upgrades @resources.upgrades do |entry|
  json.id entry.item.id
  json.name entry.item.name
  json.quantity entry.item.quantity
  json.used_count entry.used_count
  json.pledge_value entry.item.pledge_value&.to_f
  if entry.from_model
    json.from_model do
      json.partial! "api/v1/hangar_plans/model", model: entry.from_model
    end
  end
  if entry.to_model
    json.to_model do
      json.partial! "api/v1/hangar_plans/model", model: entry.to_model
    end
  end
end

# Without pictures: the store lists every priced ship, and a pick list shows none.
json.store_models @resources.store_models do |model|
  json.id model.id
  json.name model.name
  json.slug model.slug
  json.manufacturer_name model.manufacturer&.name
  json.pledge_price model.pledge_price.to_f
  json.on_sale model.on_sale || false
end

json.buybacks @resources.buybacks do |entry|
  pledge = entry.pledge
  json.id pledge.id
  json.name pledge.name
  json.kind pledge.kind
  price = (pledge.kind == "upgrade") ? pledge.upgrade_price : pledge.price
  json.price price&.to_f
  json.used entry.used
  json.lifetime_insurance pledge.lifetime_insurance
  json.insurance_months pledge.insurance_months
  json.insurance_known pledge.insurance_known?
  json.models entry.models do |model|
    json.partial! "api/v1/hangar_plans/model", model:
  end
  if pledge.upgrade_from_model
    json.upgrade_from_model do
      json.partial! "api/v1/hangar_plans/model", model: pledge.upgrade_from_model
    end
  end
  if pledge.upgrade_to_model
    json.upgrade_to_model do
      json.partial! "api/v1/hangar_plans/model", model: pledge.upgrade_to_model
    end
  end
end
