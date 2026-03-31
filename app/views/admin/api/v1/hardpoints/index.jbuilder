# frozen_string_literal: true

json.items do
  json.array! @hardpoints, partial: "admin/api/v1/hardpoints/hardpoint", as: :hardpoint
end

json.partial! "api/shared/meta", result: @hardpoints
