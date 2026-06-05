# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["SHORT_DOMAIN"] ||= "fltyrd.test"

require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rails/test_help"
require "minitest/reporters"
require "sidekiq/testing"
require "mocha/minitest"

Minitest::Reporters.use!(
  Minitest::Reporters::ProgressReporter.new(color: true),
  ENV,
  Minitest.backtrace_filter
)

Sidekiq::Testing.fake!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

OmniAuth.config.test_mode = true

def mock_omniauth(provider, uid: "123456", email: "oauth@example.com", nickname: "oauthuser", name: "OAuth User", image: nil)
  extra = case provider.to_s
  when "discord"
    {raw_info: {"verified" => true}}
  when "github"
    {all_emails: [{"email" => email, "primary" => true, "verified" => true}]}
  else
    {}
  end

  info_hash = {
    email: email,
    nickname: nickname,
    name: name,
    image: image
  }
  info_hash[:email_verified] = true if %w[google citizenid twitch].include?(provider.to_s)

  OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
    provider: provider.to_s,
    uid: uid,
    info: OmniAuth::AuthHash::InfoHash.new(info_hash),
    extra: extra,
    credentials: {
      token: "mock_token",
      refresh_token: "mock_refresh_token",
      expires_at: 1.hour.from_now.to_i,
      expires: true
    }
  )
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    include FactoryBot::Syntax::Methods
    include ActiveSupport::Testing::TimeHelpers

    teardown do
      OmniAuth.config.mock_auth.each_key do |provider|
        OmniAuth.config.mock_auth[provider] = nil
      end
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
