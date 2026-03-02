# frozen_string_literal: true

new_attr = local_assigns.fetch(:attr, nil)
old_attr = local_assigns.fetch(:old_attr, nil)

if record.try(new_attr) && record.send(new_attr).attached?
  file = record.send(new_attr)
  json.name file.filename
  json.content_type file.content_type
  json.size file.byte_size
  json.url rails_blob_url(file)
  if file.representable?
    json.small_url rails_representation_url(file.representation(resize_to_limit: [500, 500], saver: {quality: 80}))
    json.medium_url rails_representation_url(file.representation(resize_to_limit: [1000, 1000], saver: {quality: 90}))
    json.large_url rails_representation_url(file.representation(resize_to_limit: [2000, 2000], saver: {quality: 90}))
    json.xlarge_url rails_representation_url(file.representation(resize_to_limit: [3000, 3000]))
  end
  json.width file.metadata[:width]
  json.height file.metadata[:height]
  json.uploaded_at file.blob.created_at
elsif old_attr.present? && record.try(old_attr).present?
  view_image = record.send(old_attr)
  json.name view_image.file&.filename
  json.content_type view_image.file&.content_type
  json.size view_image.file&.size
  json.url view_image.url
  if view_image.file&.content_type&.start_with?("image/")
    json.small_url view_image.try(:small)&.url || view_image.url
    json.medium_url view_image.try(:medium)&.url || view_image.try(:big)&.url || view_image.try(:small)&.url || view_image.url
    json.large_url view_image.try(:large)&.url || view_image.try(:big)&.url || view_image.try(:small)&.url || view_image.url
    json.xlarge_url view_image.try(:xlarge)&.url || view_image.try(:big)&.url || view_image.url
    json.width local_assigns.fetch(:width, nil)
    json.height local_assigns.fetch(:height, nil)
  end
end
