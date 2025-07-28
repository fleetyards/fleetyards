# frozen_string_literal: true

json.ignore_nil!
json.id image.id
json.caption image.caption
json.background image.background?
json.enabled image.enabled
json.global image.global

json.partial!("api/v1/shared/view_image", record: image, attr: :file, old_attr: :name, width: image.width, height: image.height)

json.gallery do
  json.id image.gallery_id
  json.type image.gallery_type
  json.name image.gallery_name
  json.slug image.gallery_slug
end

json.partial! "api/shared/dates", record: image
