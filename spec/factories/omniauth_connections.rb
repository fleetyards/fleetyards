# frozen_string_literal: true

FactoryBot.define do
  factory :omniauth_connection do
    user
    uid { SecureRandom.hex(10) }
    provider { :discord }
    auth_payload { {provider: provider.to_s, uid: uid, info: {email: user.email}} }
  end
end
