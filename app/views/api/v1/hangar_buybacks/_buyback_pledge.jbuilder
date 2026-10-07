# frozen_string_literal: true

json.id buyback_pledge.id
json.rsi_pledge_id buyback_pledge.rsi_pledge_id
json.kind buyback_pledge.kind
json.name buyback_pledge.name
json.upgraded buyback_pledge.upgraded
json.available buyback_pledge.available
json.reclaimed_on buyback_pledge.reclaimed_on.iso8601 if buyback_pledge.reclaimed_on.present?
json.contained buyback_pledge.contained if buyback_pledge.contained.present?
json.image buyback_pledge.image_url if buyback_pledge.image_url.present?
json.upgrade_from_ship_id buyback_pledge.upgrade_from_ship_id if buyback_pledge.upgrade_from_ship_id.present?
json.upgrade_to_ship_id buyback_pledge.upgrade_to_ship_id if buyback_pledge.upgrade_to_ship_id.present?
json.upgrade_to_sku_id buyback_pledge.upgrade_to_sku_id if buyback_pledge.upgrade_to_sku_id.present?
if buyback_pledge.kind == "upgrade"
  if (upgrade_price = buyback_pledge.upgrade_price)
    json.price upgrade_price.to_f
    json.price_currency "USD"
  end
else
  json.price buyback_pledge.price.to_f if buyback_pledge.price.present?
  json.price_currency buyback_pledge.price_currency if buyback_pledge.price_currency.present?
end
json.insurance_months buyback_pledge.insurance_months if buyback_pledge.insurance_months.present?
json.lifetime_insurance buyback_pledge.lifetime_insurance
json.partial! "api/shared/dates", record: buyback_pledge
