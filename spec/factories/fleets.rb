# == Schema Information
#
# Table name: fleets
#
#  id                  :uuid             not null, primary key
#  calendar_feed_token :string
#  created_by          :uuid
#  default_timezone    :string           default("UTC"), not null
#  description         :text
#  discord             :string
#  fid                 :string
#  guilded             :string
#  homepage            :string
#  name                :string
#  normalized_fid      :string
#  public_fleet        :boolean          default(FALSE)
#  public_fleet_stats  :boolean          default(FALSE)
#  rsi_sid             :string
#  sid                 :string
#  slug                :string
#  ts                  :string
#  twitch              :string
#  youtube             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_fleets_on_calendar_feed_token  (calendar_feed_token) UNIQUE
#  index_fleets_on_fid                  (fid) UNIQUE
#
FactoryBot.define do
  factory :fleet do
    transient do
      members { [] }
      officers { [] }
      admins { [] }
    end

    name { Faker::Alphanumeric.alphanumeric(number: 10) }
    fid { Faker::Alphanumeric.alphanumeric(number: 3).upcase }
    public_fleet { true }

    trait :private do
      public_fleet { false }
    end

    trait :with_public_stats do
      public_fleet_stats { true }
    end

    trait :with_description do
      description { Faker::Lorem.paragraph }
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/test.png"), "image/png") }
    end

    trait :with_background_image do
      background_image { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/image.jpg"), "image/jpeg") }
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
