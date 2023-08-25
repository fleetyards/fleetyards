# frozen_string_literal: true

if media_image.present?
  json.source media_image.url
  json.small media_image.small.url
  json.medium media_image.medium.url
  json.large media_image.large.url
end
