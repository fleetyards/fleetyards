# frozen_string_literal: true

model_preload = HangarPlans::MODEL_PRELOAD
slots = hangar_plan.slots.includes(candidates: [
  :model_paint,
  {model: model_preload},
  {acquisitions: [{start_model: model_preload}, :buyback_pledge, {source_vehicle: :model},
    {upgrade_steps: [{origin_model: model_preload}, {target_model: model_preload}, :hangar_pledge_item, :buyback_pledge]}]}
]).to_a
melts = hangar_plan.melts.includes({model: model_preload}, :vehicle).to_a

# Every route and melt asks its plan about the live hangar; one plan answers
# them all, so it is asked once.
slots.flat_map(&:candidates).flat_map(&:acquisitions).each do |acquisition|
  acquisition.association(:hangar_plan).target = hangar_plan
  acquisition.upgrade_steps.each { |step| step.association(:hangar_plan).target = hangar_plan }
end
melts.each { |melt| melt.association(:hangar_plan).target = hangar_plan }

owned = hangar_plan.live_vehicles.where.not(id: hangar_plan.used_vehicle_ids).group(:model_id).count

json.id hangar_plan.id
json.name hangar_plan.name
json.description hangar_plan.description
json.based_on_at hangar_plan.based_on_at.utc.iso8601
json.starting_credit hangar_plan.starting_credit.to_f
json.shared hangar_plan.shared?
json.share_token hangar_plan.share_token unless local_assigns[:public_view]
json.slots_count slots.size

json.slots slots do |slot|
  json.id slot.id
  json.label slot.label
  json.description slot.description
  json.filters slot.filters.slice(*HangarPlanSlot::FILTERS).transform_keys { |key| key.camelize(:lower) }
  json.quantity slot.quantity
  json.position slot.position
  json.state slot.state

  json.candidates slot.candidates do |candidate|
    json.id candidate.id
    json.position candidate.position
    json.model do
      json.partial! "api/v1/hangar_plans/model", model: candidate.model
    end
    json.model_paint_id candidate.model_paint_id
    json.paint_name candidate.model_paint&.name
    json.model_module_ids candidate.model_module_ids
    json.model_upgrade_ids candidate.model_upgrade_ids
    json.owned_count owned.fetch(candidate.model_id, 0)
    json.matches_filters slot.matches?(candidate.model)
    json.acquisitions candidate.acquisitions, partial: "api/v1/hangar_plans/acquisition", as: :acquisition
  end
end

json.melts melts do |melt|
  json.id melt.id
  json.vehicle_id melt.vehicle_id
  json.vehicle_name melt.vehicle&.name unless local_assigns[:public_view]
  json.model do
    json.partial! "api/v1/hangar_plans/model", model: melt.model
  end
  json.value_override melt.value_override&.to_f
  json.value melt.value&.to_f
  json.estimated melt.estimated?
  json.vehicle_missing melt.vehicle_missing?
end

json.partial! "api/shared/dates", record: hangar_plan
