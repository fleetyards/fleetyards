# encoding: utf-8
# frozen_string_literal: true

json.id image.id
json.name image.name.file.filename
json.url image.name.url
json.type image.name.content_type
json.small do
  json.url image.name.small.url
end
json.big do
  json.url image.name.big.url
end
json.dark do
  json.url image.name.dark.url
end
