# frozen_string_literal: true

json.id cargo_hold.id
json.model_id cargo_hold.model_id
json.name cargo_hold.name
json.position cargo_hold.position
json.capacity_scu cargo_hold.capacity_scu.to_f
json.dimension_x cargo_hold.dimension_x.to_f
json.dimension_y cargo_hold.dimension_y.to_f
json.dimension_z cargo_hold.dimension_z.to_f
json.offset_x cargo_hold.offset_x&.to_f
json.offset_y cargo_hold.offset_y&.to_f
json.offset_z cargo_hold.offset_z&.to_f
json.rotation cargo_hold.rotation

json.model do
  json.id cargo_hold.model.id
  json.name cargo_hold.model.name
  json.slug cargo_hold.model.slug
end

json.partial! "api/shared/dates", record: cargo_hold
