# frozen_string_literal: true

attr = local_assigns.fetch(:attr, nil)

if record.try(attr) && record.send(attr).attached?
  file = record.send(attr)
  json.name file.filename
  json.content_type file.content_type
  json.size file.byte_size
  json.url rails_blob_url(file)
  if file.representable?
    json.small_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:small]))
    json.medium_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:medium]))
    json.large_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:large]))
    json.xlarge_url rails_representation_url(file.representation(ActiveStorageVariants::REPRESENTATION_SIZES[:xlarge]))
  end
  json.width file.metadata[:width]
  json.height file.metadata[:height]
  json.uploaded_at file.blob.created_at
end
