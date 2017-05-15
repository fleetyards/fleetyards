# frozen_string_literal: true

module CarrierWave
  module MiniMagick
    def quality(percentage)
      manipulate! do |img|
        img.quality(percentage.to_s)
        img = yield(img) if block_given?
        img
      end
    end

    def darken(percentage)
      manipulate! do |img|
        img.fill("black")
        img.colorize("#{percentage}%")
        img = yield(img) if block_given?
        img
      end
    end
  end
end

CarrierWave.configure do |config|
  if Rails.env.production?
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     Rails.application.secrets[:aws_key],
      aws_secret_access_key: Rails.application.secrets[:aws_secret],
      region:                'eu-west-1'
    }
    config.fog_directory = 'fleetyards'
    config.asset_host = "https://d159vi9qupesbj.cloudfront.net"
  end
end
