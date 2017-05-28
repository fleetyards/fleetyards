# encoding: utf-8
# frozen_string_literal: true

json.cache! ['v1', image] do
  json.id image.id
  json.name image.name.file.filename
  json.url image.name.url
  json.small do
    json.url image.name.small.url
  end
  json.dark do
    json.url image.name.dark.url
  end
  json.partial! 'api/shared/dates', record: image
end
