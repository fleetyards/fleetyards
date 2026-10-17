# frozen_string_literal: true

json.array! @options do |component|
  json.component { json.partial! "api/v1/loadout_slots/component", component: }

  json.slots @ports.fetch(component.id, []).sort_by(&:sc_name) do |port|
    slot = LoadoutSlots::Slot.new(path: port.sc_name, port:, instance: nil, stock: port.facts.component)
    json.partial! "api/v1/loadout_slots/slot", slot:, loadout_slots: nil
  end
end
