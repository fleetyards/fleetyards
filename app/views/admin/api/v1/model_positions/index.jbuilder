# frozen_string_literal: true

json.items do
  json.array! @model_positions, partial: "admin/api/v1/model_positions/model_position", as: :model_position
end

json.partial! "api/shared/meta", result: @model_positions
