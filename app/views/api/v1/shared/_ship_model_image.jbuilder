# frozen_string_literal: true

image_attr = if model.store_image.attached?
  :store_image
elsif model.angled_view.attached?
  :angled_view
elsif model.fleetchart_image.attached?
  :fleetchart_image
end

if image_attr
  json.image do
    json.partial! "api/v1/shared/file", record: model, attr: image_attr
  end
else
  json.image nil
end
