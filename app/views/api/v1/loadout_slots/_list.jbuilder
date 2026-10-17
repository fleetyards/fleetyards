# frozen_string_literal: true

json.array! loadout_slots.fittable_hull do |slot|
  json.partial! "api/v1/loadout_slots/slot", slot:, loadout_slots:
end
