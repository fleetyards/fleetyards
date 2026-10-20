# frozen_string_literal: true

json.id step.id
json.source_kind step.source_kind
json.from_model do
  json.partial! "api/v1/hangar_plans/model", model: step.origin_model
end
json.to_model do
  json.partial! "api/v1/hangar_plans/model", model: step.target_model
end
json.hangar_pledge_item_id step.hangar_pledge_item_id
json.buyback_pledge_id step.buyback_pledge_id
json.price_override step.price_override&.to_f
json.price step.price&.to_f
json.source_missing step.source_missing?
