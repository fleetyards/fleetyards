# frozen_string_literal: true

if view_image.present?
  json.source view_image.url
  json.small view_image.small.url
  json.medium view_image.medium.url
  json.large view_image.large.url
  json.xlarge view_image.xlarge.url
  json.width width
  json.height height
end
