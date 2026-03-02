# frozen_string_literal: true

json.array! @model_paints, partial: "admin/api/v1/model_paints/model_paint", as: :model_paint
