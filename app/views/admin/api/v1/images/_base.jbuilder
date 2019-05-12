# frozen_string_literal: true

dimensions = if image.width.present? && image.height.present?
               [image.width, image.height]
             else
               ::MiniMagick::Image.open(image.name.file.file)[:dimensions]
             end

json.id image.id
json.name image.name.file.filename
json.size image.name.file.size
json.url image.name.url
json.width dimensions[0]
json.height dimensions[1]
json.type image.name.content_type
json.enabled image.enabled
json.background image.background?
json.small_url image.name.small.url
json.big_url image.name.big.url
