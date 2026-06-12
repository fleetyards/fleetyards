# == Schema Information
#
# Table name: fleet_invite_urls
#
#  id            :uuid             not null, primary key
#  expires_after :datetime
#  limit         :integer
#  token         :string
#  usage_count   :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  fleet_id      :uuid
#  user_id       :uuid
#
# Indexes
#
#  index_fleet_invite_urls_on_token  (token) UNIQUE
#
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
