# frozen_string_literal: true

json.cache! ['v1', image] do
  json.partial! 'api/v1/images/base', image: image
  json.model do
    json.partial! 'api/v1/images/model', model: image.gallery
  end
  json.partial! 'api/shared/dates', record: image
end
