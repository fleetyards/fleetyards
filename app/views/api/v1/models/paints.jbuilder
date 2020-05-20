# frozen_string_literal: true

json.array! @paints, partial: 'api/v1/model_paints/minimal', as: :model_paint
