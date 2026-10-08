FactoryBot.define do
  factory :fleet_invite_url do
    fleet
    user

    trait :with_limit do
      limit { 10 }
    end

    trait :with_expiration do
      expires_after { 7.days.from_now }
    end

    trait :expired do
      expires_after { 1.day.ago }
    end

    trait :unlimited do
      limit { nil }
      expires_after { nil }
    end
  end
end
