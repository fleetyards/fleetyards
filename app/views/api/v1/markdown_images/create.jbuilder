# frozen_string_literal: true

width, height = @markdown_image.display_dimensions

json.id @markdown_image.id
json.url api_v1_markdown_image_url(@markdown_image)
json.width width
json.height height
