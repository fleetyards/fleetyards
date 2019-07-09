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
    config.storage NullStorage
    config.enable_processing = false
  end

  config.asset_host = Rails.application.secrets[:frontend_endpoint] if Rails.env.development?

  if Rails.env.production? || Rails.env.staging?
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: Rails.application.secrets.aws_access_key_id,
      aws_secret_access_key: Rails.application.secrets.aws_secret_access_key,
      use_iam_profile: true,
      region: Rails.application.secrets.aws_s3_region,
      host: 's3.amazonaws.com',
      endpoint: 'https://s3.amazonaws.com'
    }

    config.asset_host = 'https://cdn.s3.fleetyards.net' if Rails.env.production?
    config.fog_directory = Rails.application.secrets.aws_s3_bucket

    config.fog_public = true
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  end
end
