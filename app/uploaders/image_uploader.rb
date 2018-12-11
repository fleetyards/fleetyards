# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  process :store_dimensions

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :small do
    process resize_to_limit: [500, 500]
    process quality: 80
  end

  version :big do
    process resize_to_limit: [1000, 1000]
    process quality: 90
  end

  def extension_white_list
    %w[jpg jpeg png]
  end

  private def store_dimensions
    return unless file || model

    model.width, model.height = ::MiniMagick::Image.open(file.file)[:dimensions]
  end
end
