# frozen_string_literal: true

attr = local_assigns.fetch(:attr, nil)

if record.try(attr) && record.send(attr).attached?
  file = record.send(attr)
  json.name file.filename
  json.content_type file.content_type
  json.size file.byte_size
  json.url rails_blob_url(file)
  json.signed_id file.blob.signed_id
  if file.representable?
    json.small_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:small]))
    json.medium_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium]))
    json.large_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:large]))
    json.xlarge_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:xlarge]))
  elsif ActiveStorageVariants::VECTOR_CONTENT_TYPES.include?(file.content_type)
    # A vector has no representations, but every caller asks for a size --
    # `smallUrl` is what the panels draw -- and for this one file all four
    # sizes are the same picture.
    json.small_url rails_blob_url(file)
    json.medium_url rails_blob_url(file)
    json.large_url rails_blob_url(file)
    json.xlarge_url rails_blob_url(file)
  end
  json.width file.metadata[:width]
  json.height file.metadata[:height]
  json.uploaded_at file.blob.created_at
end
