# frozen_string_literal: true

class StoreImageUploader < BaseUploader
  include CarrierWave::MiniMagick

  def default_url(*_args)
    ActionController::Base.helpers.asset_url('fallback/store_image.jpg', host: Rails.configuration.app.frontend_endpoint)
  end

  version :large do
    process resize_to_limit: [2400, 2400]
    process quality: 90
  end

  version :medium do
    process resize_to_fill: [800, 280]
    process quality: 90
  end

  version :small do
    process resize_to_limit: [300, 300]
    process quality: 80
  end

  def extension_white_list
    %w[jpg jpeg png]
  end
end
