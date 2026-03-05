# frozen_string_literal: true

json.id dock.id
json.name dock.name
json.dock_type dock.dock_type
json.dock_type_label dock.dock_type_label
json.ship_size dock.ship_size
json.ship_size_label dock.ship_size_label
json.group dock.group
json.length dock.length&.to_f
json.beam dock.beam&.to_f
json.height dock.height&.to_f
json.min_ship_size dock.min_ship_size
json.max_ship_size dock.max_ship_size
json.model_id dock.model_id

json.partial! "api/shared/dates", record: dock
