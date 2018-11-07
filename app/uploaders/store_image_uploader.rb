# frozen_string_literal: true

class StoreImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def default_url(*_args)
    host = 'https://api.fleetyards.net'
    host = 'http://api.fleetyards.test' if Rails.env.development?
    ActionController::Base.helpers.asset_url('fallback/store_image.jpg', host: host)
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_white_list
    %w[jpg jpeg png]
  end
end
