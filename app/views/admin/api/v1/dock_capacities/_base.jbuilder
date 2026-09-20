# frozen_string_literal: true

json.id dock_capacity.id
json.dock_id dock_capacity.dock_id
json.ladder dock_capacity.ladder
json.size dock_capacity.size
json.size_label dock_capacity.size_label
json.quantity dock_capacity.quantity
json.display dock_capacity.display

json.partial! "api/shared/dates", record: dock_capacity
