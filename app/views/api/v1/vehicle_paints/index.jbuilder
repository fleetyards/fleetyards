# frozen_string_literal: true

json.array! @paints do |paint|
  json.owned @owned_ids.include?(paint.id)
  json.applied paint.id == @vehicle.model_paint_id
  json.paint do
    json.partial! "api/v1/model_paints/model_paint", model_paint: paint
  end
end
