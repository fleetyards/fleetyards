# frozen_string_literal: true

json.id acquisition.id
json.start_kind acquisition.start_kind
unless local_assigns[:public_view]
  json.source_vehicle_id acquisition.source_vehicle_id
  json.buyback_pledge_id acquisition.buyback_pledge_id
end
json.start_model do
  json.partial! "api/v1/hangar_plans/model", model: acquisition.start_model
end
json.price_override acquisition.price_override&.to_f
json.price acquisition.price&.to_f
json.uses_buyback_token acquisition.uses_buyback_token
json.source_missing local_assigns[:public_view] ? false : acquisition.source_missing?
json.steps do
  json.array! acquisition.upgrade_steps do |step|
    json.partial! "api/v1/hangar_plans/upgrade_step", step:, public_view: local_assigns[:public_view]
  end
end
