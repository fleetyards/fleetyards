# frozen_string_literal: true

json.id cargo_hold.id
json.parent_type cargo_hold.parent_type
json.parent_id cargo_hold.parent_id
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

json.parent do
  json.id cargo_hold.parent.id
  json.name cargo_hold.parent.name
  json.slug cargo_hold.parent.try(:slug)
end

json.partial! "api/shared/dates", record: cargo_hold
