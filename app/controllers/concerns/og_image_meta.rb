# frozen_string_literal: true

# The picture a link preview shows, with the size and description a crawler
# reads alongside it.
module OgImageMeta
  extend ActiveSupport::Concern

  BUNDLED_IMAGE_SIZES = Concurrent::Map.new

  # `image` is an attachment, or the path of an image bundled with the frontend.
  # An attachment's size is known once Active Storage has analysed it and is
  # left out until then; a bundled image's is read from the file itself.
  private def use_og_image(image, alt: nil)
    return if image.blank?

    if image.is_a?(String)
      @og_image = helpers.vite_asset_url(image)
      @og_image_width, @og_image_height = bundled_image_size(image)
    else
      @og_image = rails_blob_url(image)
      @og_image_width = image.metadata[:width]
      @og_image_height = image.metadata[:height]
    end
    @og_image_alt = alt
  end

  private def bundled_image_size(path)
    BUNDLED_IMAGE_SIZES.compute_if_absent(path) do
      require "vips"

      # Only the header is read; the pixels are never decoded.
      image = Vips::Image.new_from_file(Rails.root.join("app/frontend", path).to_s)
      [image.width, image.height]
    rescue Vips::Error
      []
    end
  end
end
