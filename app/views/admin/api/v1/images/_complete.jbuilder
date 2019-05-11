# frozen_string_literal: true

json.cache! ['v1', image] do
  json.partial! 'admin/api/v1/images/base', image: image
  json.gallery do
    json.partial! 'api/v1/images/gallery', gallery: image.gallery if image.gallery.present?
  end
  json.gallery nil if image.gallery.blank?
  json.partial! 'api/shared/dates', record: image
end
