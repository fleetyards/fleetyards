# frozen_string_literal: true

json.id image.id
json.name image.name.file.filename
json.caption image.caption
json.url image.name.url
json.width image.width
json.height image.height
json.type image.name.content_type
json.background image.background?
json.small_url image.name.small.url
json.big_url image.name.big.url
