# frozen_string_literal: true

json.vehicles @resources.vehicles do |entry|
  json.id entry.vehicle.id
  json.name entry.vehicle.name
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: entry.vehicle.model
  end
  json.used_by entry.used_by
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

json.buybacks @resources.buybacks do |entry|
  pledge = entry.pledge
  json.id pledge.id
  json.name pledge.name
  json.kind pledge.kind
  price = (pledge.kind == "upgrade") ? pledge.upgrade_price : pledge.price
  json.price price&.to_f
  json.used entry.used
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
