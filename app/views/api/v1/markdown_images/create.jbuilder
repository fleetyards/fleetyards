# frozen_string_literal: true

width, height = @markdown_image.display_dimensions

json.id @markdown_image.id
json.url rails_representation_url(@markdown_image.display_representation)
json.width width
json.height height
