# frozen_string_literal: true

require 'fog/aws'

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
        img.fill('black')
        img.colorize("#{percentage}%")
        img = yield(img) if block_given?
        img
      end
    end
  end
end

# NullStorage provider for CarrierWave for use in tests.  Doesn't actually
# upload or store files but allows test to pass as if files were stored and
# the use of fixtures.
class NullStorage
  attr_reader :uploader

  def initialize(uploader)
    @uploader = uploader
  end

  def identifier
    uploader.filename
  end

  def store!(_file)
    true
  end

  def retrieve!(_identifier)
    true
  end
end

CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
    # elsif Rails.env.development? || ENV['CI'].present?
  else
    config.storage :file
    config.asset_host = Rails.application.secrets[:frontend_endpoint]
    # else
    #   config.fog_provider = 'fog/aws'
    #   config.fog_credentials = {
    #     provider: 'AWS',
    #     aws_access_key_id: Rails.application.secrets.aws_access_key_id,
    #     aws_secret_access_key: Rails.application.secrets.aws_secret_access_key,
    #     region: Rails.application.secrets.aws_s3_region
    #   }

    #   config.storage :fog

    #   config.fog_directory = Rails.application.secrets.aws_s3_bucket
    #   config.fog_public = true

    #   # config.asset_host = 'https://cdn.s3.fleetyards.net' if Rails.env.production?
    #   config.asset_host = 'https://fleetyards.s3-eu-west-1.amazonaws.com' if Rails.env.production?
    #   config.asset_host = 'https://fleetyards-stage.s3.eu-central-1.amazonaws.com' if Rails.env.staging?
  end
end
