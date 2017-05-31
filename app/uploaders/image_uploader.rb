# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::ImageOptimizer
  include CarrierWave::MiniMagick

  storage Rails.env.production? ? :fog : :file

  process :optimize if Rails.env.production?

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :small do
    process resize_to_limit: [300, 300]
    process quality: 60
    process optimize: [{ quality: 60 }] if Rails.env.production?
  end

  version :big do
    process resize_to_limit: [1000, 1000]
    process quality: 90
    process optimize: [{ quality: 90 }] if Rails.env.production?
  end

  version :dark do
    process darken: 60
  end

  def extension_white_list
    %w[jpg jpeg png]
  end
end
