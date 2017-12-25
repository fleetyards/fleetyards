# frozen_string_literal: true

json.id image.id
json.name image.name.file.filename
json.url image.name.url
json.type image.name.content_type
json.background image.background?
json.small_url image.name.small.url
json.big_url image.name.big.url
json.dark_url image.name.dark.url
