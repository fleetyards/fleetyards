if file.attached?
  json.name file.filename
  json.content_type file.content_type
  json.size file.byte_size
  json.url rails_blob_url(file)
  if file.representable?
    json.small_url rails_representation_url(file.representation(resize_to_limit: [500, 500], quality: 80))
    json.medium_url rails_representation_url(file.representation(resize_to_limit: [1000, 1000], quality: 90))
    json.large_url rails_representation_url(file.representation(resize_to_limit: [2000, 2000], quality: 90))
    json.xlarge_url rails_representation_url(file.representation(resize_to_limit: [3000, 3000]))
  end
  if file.previewable?
    json.preview_url rails_preview_url(file.preview(resize_to_limit: [500, 500], quality: 80))
  end
  json.width file.metadata[:width]
  json.height file.metadata[:height]
  json.uploaded_at file.blob.created_at
end
