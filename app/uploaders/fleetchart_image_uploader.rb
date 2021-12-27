# frozen_string_literal: true

class FleetchartImageUploader < BaseUploader
  include CarrierWave::MiniMagick

  process :store_dimensions

  version :small do
    process resize_to_limit: [500, 500]
  end

  version :medium do
    process resize_to_limit: [1000, 1000]
  end

  version :large do
    process resize_to_limit: [2000, 2000]
  end

  version :xlarge do
    process resize_to_limit: [3000, 3000]
  end

  def extension_allowlist
    %w[png webp]
  end

  private def store_dimensions
    return unless file || model

    width, height = ::MiniMagick::Image.open(file.file)[:dimensions]

    model.send("#{mounted_as}_width=", width)
    model.send("#{mounted_as}_height=", height)
  end
end
