# frozen_string_literal: true

json.array! @bodykits do |(slot, component)|
  json.slot slot.sc_name
  json.stock component.id == slot.facts.component&.id
  json.component { json.partial! "api/v1/loadout_slots/component", component: }
end
