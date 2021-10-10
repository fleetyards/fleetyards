# frozen_string_literal: true

class AvatarUploader < BaseUploader
  include CarrierWave::MiniMagick

  version :small do
    process resize_to_limit: [400, 400]
    process quality: 80
  end

  def extension_allowlist
    %w[jpg jpeg png webp]
  end
end
