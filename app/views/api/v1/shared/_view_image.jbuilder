# frozen_string_literal: true

new_attr = local_assigns.fetch(:attr, nil)
old_attr = local_assigns.fetch(:old_attr, nil)

if record.try(new_attr) && record.send(new_attr).attached?
  json.partial! "api/v1/shared/file", file: record.send(new_attr)
elsif old_attr.present? && record.try(old_attr)&.present?
  view_image = record.send(old_attr)
  json.url view_image.url
  json.small_url view_image.small.url
  json.medium_url view_image.medium.url
  json.large_url view_image.large.url
  json.xlarge_url view_image.xlarge.url
  json.width local_assigns.fetch(:width, nil)
  json.height local_assigns.fetch(:height, nil)
end
