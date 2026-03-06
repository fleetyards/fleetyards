# frozen_string_literal: true

json.items do
  json.array! @model_hardpoints, partial: "admin/api/v1/model_hardpoints/model_hardpoint", as: :model_hardpoint
end

json.partial! "api/shared/meta", result: @model_hardpoints
