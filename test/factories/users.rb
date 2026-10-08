FactoryBot.define do
  factory :user do
    transient do
      vehicle_count { 0 }
      wanted_vehicle_count { 0 }
    end

    username { Faker::Alphanumeric.alphanumeric(number: 10) }
    sequence(:email) { |n| Faker::Internet.email(name: "user#{n}") }
    password { Faker::Internet.password }
    password_confirmation { password }
    confirmed_at { Time.now }

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_rsi_handle do
      rsi_handle { Faker::Alphanumeric.alphanumeric(number: 10) }
    end

    trait :with_social_links do
      discord { "https://discord.gg/test" }
      twitch { "https://twitch.tv/test" }
      youtube { "https://youtube.com/@test" }
      homepage { "https://example.com" }
      guilded { "https://guilded.gg/test" }
    end

    trait :tester do
      tester { true }
    end

    trait :public_hangar do
      public_hangar { true }
      public_hangar_loaners { true }
      public_hangar_stats { true }
      public_wishlist { true }
    end

    trait :private_hangar do
      public_hangar { false }
      public_hangar_loaners { false }
      public_hangar_stats { false }
      public_wishlist { false }
    end

    trait :hide_owner do
      hide_owner { true }
    end

    trait :oauth_only do
      password_set_manually { false }

      after(:create) do |user|
        create(:omniauth_connection, user: user, provider: :discord)
      end
    end

    after(:create) do |user, evaluator|
      evaluator.vehicle_count.times do
        create(:vehicle, user: user)
      end

      evaluator.wanted_vehicle_count.times do
        create(:vehicle, user: user, wanted: true)
      end
    end
  end
end
