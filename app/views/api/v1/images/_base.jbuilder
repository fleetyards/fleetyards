# frozen_string_literal: true

json.id image.id
json.name image.name.file.filename
json.caption image.caption
json.url image.name.url
json.width image.width
json.height image.height
json.type image.name.content_type
json.background image.background?
json.small_url image.name.small.url
json.big_url image.name.big.url

if local_assigns.fetch(:extended, false)
  json.gallery do
    json.partial!("api/v1/images/gallery", gallery: image.gallery, image:) if image.gallery.present?
  end
end

json.partial! "api/shared/dates", record: image
