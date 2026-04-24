# frozen_string_literal: true

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

RSpec.configure do |config|
  config.after(:each) do
    OmniAuth.config.mock_auth.keys.each do |provider|
      OmniAuth.config.mock_auth[provider] = nil
    end
  end
end
