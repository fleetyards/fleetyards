# frozen_string_literal: true

OmniAuth.config.test_mode = true

def mock_omniauth(provider, uid: "123456", email: "oauth@example.com", nickname: "oauthuser", name: "OAuth User", image: nil)
  OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
    provider: provider.to_s,
    uid: uid,
    info: OmniAuth::AuthHash::InfoHash.new(
      email: email,
      nickname: nickname,
      name: name,
      image: image
    ),
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
