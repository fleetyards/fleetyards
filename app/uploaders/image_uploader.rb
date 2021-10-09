# frozen_string_literal: true

class ImageUploader < BaseUploader
  include CarrierWave::MiniMagick

  process :store_dimensions

  version :small do
    process resize_to_limit: [500, 500]
    process quality: 80
  end

  version :big do
    process resize_to_limit: [1000, 1000]
    process quality: 90
  end

  def extension_allowlist
    %w[jpg jpeg png webp]
  end

  private def store_dimensions
    return unless file || model

    model.width, model.height = ::MiniMagick::Image.open(file.file)[:dimensions]
  end
end
