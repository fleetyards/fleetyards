# frozen_string_literal: true

# The paint picture picked in the gallery. Omitted rather than null, like the
# uploaded image and the gallery image beside it.
paint = vehicle.model_paint_picture
if paint.present? && paint.store_image.attached?
  json.paint_picture do
    json.partial! "api/v1/shared/file", record: paint, attr: :store_image
  end
end
