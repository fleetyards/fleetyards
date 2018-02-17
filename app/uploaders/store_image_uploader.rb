# frozen_string_literal: true

class StoreImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::ImageOptimizer
  include CarrierWave::MiniMagick

  storage Rails.env.production? ? :fog : :file

  process :optimize if Rails.env.production?

  def default_url(*_args)
    ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.jpg"].compact.join('_'))
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def filename
    "#{super.chomp(File.extname(super))}-#{model.store_images_updated_at.to_i}#{File.extname(super)}" if original_filename.present?
  end

  version :small do
    process resize_to_limit: [500, 500]
    process quality: 80
    process optimize: [{ quality: 80 }] if Rails.env.production?
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
