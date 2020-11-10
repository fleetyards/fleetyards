# frozen_string_literal: true

json.array! @model_paints, partial: 'admin/api/v1/model_paints/minimal', as: :model_paint
