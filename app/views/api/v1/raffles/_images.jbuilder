# frozen_string_literal: true

# The same shape as a single attached file (api/v1/shared/_file), one per
# gallery image, in upload order: the first is the cover.
json.images raffle.ordered_images do |image|
  json.name image.filename
  json.content_type image.content_type
  json.size image.byte_size
  json.url rails_blob_url(image)
  json.signed_id image.blob.signed_id
  if image.representable?
    ActiveStorageVariants::REPRESENTATION_SIZES.slice(:small, :medium, :large, :xlarge).each do |size, transformations|
      json.set! "#{size}_url", rails_representation_url(image.representation(transformations))
    end
  end
  json.width image.metadata[:width]
  json.height image.metadata[:height]
  json.uploaded_at image.blob.created_at
end
