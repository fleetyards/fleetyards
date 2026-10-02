# == Schema Information
#
# Table name: fleets
#
#  id                          :uuid             not null, primary key
#  alignment                   :string
#  allies_fleet                :boolean          default(FALSE), not null
#  allies_fleet_members        :boolean          default(FALSE), not null
#  allies_fleet_stats          :boolean          default(FALSE), not null
#  calendar_feed_token         :string
#  commitment                  :string
#  created_by                  :uuid
#  default_timezone            :string           default("UTC"), not null
#  description                 :text
#  discarded_at                :datetime
#  discord                     :string
#  fid                         :string
#  guilded                     :string
#  homepage                    :string
#  inventory_transfer_policy   :integer          default("everyone"), not null
#  language                    :string
#  listed                      :boolean
#  name                        :string
#  normalized_fid              :string
#  primary_activity            :string
#  public_fleet                :boolean          default(FALSE)
#  public_fleet_stats          :boolean          default(FALSE)
#  recruiting                  :boolean
#  roleplay                    :boolean
#  rsi_sid                     :string
#  rsi_synced_at               :datetime
#  rsi_verification_checked_at :datetime
#  rsi_verification_status     :string
#  rsi_verification_token      :string
#  rsi_verified_at             :datetime
#  rsi_verified_sid            :string
#  secondary_activity          :string
#  sid                         :string
#  slug                        :string
#  squadrons_enabled           :boolean          default(FALSE), not null
#  transfers_blocked_at        :datetime
#  transfers_blocked_reason    :text
#  ts                          :string
#  twitch                      :string
#  youtube                     :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_fleets_on_calendar_feed_token  (calendar_feed_token) UNIQUE
#  index_fleets_on_discarded_at         (discarded_at)
#  index_fleets_on_fid                  (fid) UNIQUE WHERE (discarded_at IS NULL)
#  index_fleets_on_rsi_verified_sid     (rsi_verified_sid) UNIQUE WHERE (discarded_at IS NULL)
#
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
