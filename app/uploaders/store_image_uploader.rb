# frozen_string_literal: true

class StoreImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::ImageOptimizer
  include CarrierWave::MiniMagick

  storage Rails.env.production? ? :fog : :file

  process :optimize if Rails.env.production?

  def default_url(*_args)
    ActionController::Base.helpers.asset_path('fallback/store_image.jpg')
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def filename
    "#{super.chomp(File.extname(super))}-#{model.store_images_updated_at.to_i}#{File.extname(super)}" if original_filename.present?
  end

  def extension_white_list
    %w[jpg jpeg png]
  end
end
