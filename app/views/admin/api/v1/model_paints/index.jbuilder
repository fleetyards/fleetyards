# frozen_string_literal: true

json.items do
  json.array! @model_paints, partial: "admin/api/v1/model_paints/model_paint", as: :model_paint
end
json.partial! "api/shared/meta", result: @model_paints
