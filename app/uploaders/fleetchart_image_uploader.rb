# frozen_string_literal: true

class FleetchartImageUploader < CarrierWave::Uploader::Base
  storage Rails.env.production? ? :fog : :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :small do
    process resize_to_limit: [500, 500]
  end

  def extension_white_list
    %w[png]
  end
end
