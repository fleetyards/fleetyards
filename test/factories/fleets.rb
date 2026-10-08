FactoryBot.define do
  factory :fleet do
    transient do
      members { [] }
      officers { [] }
      admins { [] }
    end

    name { Faker::Alphanumeric.alphanumeric(number: 10) }
    sequence(:fid) { |n| "#{Faker::Alphanumeric.alphanumeric(number: 3).upcase}#{n}" }
    public_fleet { true }

    trait :private do
      public_fleet { false }
    end

    trait :with_public_stats do
      public_fleet_stats { true }
    end

    trait :with_squadrons do
      squadrons_enabled { true }
    end

    trait :with_description do
      description { Faker::Lorem.paragraph }
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_background_image do
      background_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg") }
    end

    # Past the verification check, which is what the RSI org page is for; the
    # SID has to be given.
    trait :rsi_verified do
      after(:create) do |fleet|
        fleet.update_columns(rsi_verified_at: Time.current, rsi_verified_sid: fleet.rsi_sid, rsi_verification_status: :verified)
      end
    end

    trait :with_social_links do
      discord { "https://discord.gg/test" }
      twitch { "https://twitch.tv/test" }
      youtube { "https://youtube.com/@test" }
      homepage { "https://example.com" }
      guilded { "https://guilded.gg/test" }
    end

    after(:create) do |fleet, evaluator|
      evaluator.admins.each do |member|
        create(:fleet_membership, fleet: fleet, user: member, fleet_role: fleet.fleet_roles.ranked.first, aasm_state: :accepted)
      end

      evaluator.officers.each do |member|
        create(:fleet_membership, fleet: fleet, user: member, fleet_role: fleet.fleet_roles.ranked.second, aasm_state: :accepted)
      end

      evaluator.members.each do |member|
        create(:fleet_membership, fleet: fleet, user: member, fleet_role: fleet.fleet_roles.ranked.last, aasm_state: :accepted)
      end
    end
  end
end
