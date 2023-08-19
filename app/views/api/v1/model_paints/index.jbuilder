# frozen_string_literal: true

json.array! @paints, partial: "api/v1/model_paints/model_paint", as: :model_paint
