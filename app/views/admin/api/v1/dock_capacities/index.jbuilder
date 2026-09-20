# frozen_string_literal: true

json.items do
  json.array! @dock_capacities, partial: "admin/api/v1/dock_capacities/dock_capacity", as: :dock_capacity
end

json.partial! "api/shared/meta", result: @dock_capacities
