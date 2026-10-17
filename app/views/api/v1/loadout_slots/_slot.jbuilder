# frozen_string_literal: true

# One slot of a fitting and, unless `slots` is false, everything below it.
# `loadout_slots` is nil for a slot that belongs to no fitting -- a port a
# candidate component would bring.
facts = slot.facts

json.name slot.name
json.hardpoint_id slot.port.id
json.category facts.category
json.min_size facts.min_size
json.max_size facts.max_size
json.types Array(facts.types).compact_blank
json.editable slot.editable?
json.swappable loadout_slots ? loadout_slots.swappable?(slot) : slot.editable?

if slot.stock.present?
  json.stock { json.partial! "api/v1/loadout_slots/component", component: slot.stock }
end

json.emptied true if loadout_slots&.emptied?(slot.path)

fitted = loadout_slots&.fitted(slot.path)
if fitted.is_a?(Component)
  json.fitted { json.partial! "api/v1/loadout_slots/component", component: fitted }
end

children = loadout_slots ? loadout_slots.children(slot) : []
json.slots children do |child|
  json.partial! "api/v1/loadout_slots/slot", slot: child, loadout_slots:
end
