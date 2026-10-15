# frozen_string_literal: true

json.array! @paints do |paint|
  json.owned @owned_ids.include?(paint.id)
  json.pledged @pledged_ids.include?(paint.id)
  json.picture @vehicle.picture_type == "ModelPaint" && paint.id == @vehicle.picture_id
  json.paint do
    json.partial! "api/v1/model_paints/model_paint", model_paint: paint
  end
end
