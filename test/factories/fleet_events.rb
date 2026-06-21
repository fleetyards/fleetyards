# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_events
#
#  id                        :uuid             not null, primary key
#  archived_at               :datetime
#  auto_lock_enabled         :boolean          default(TRUE), not null
#  auto_lock_minutes_before  :integer          default(60), not null
#  briefing                  :text
#  cancelled_reason          :text
#  category                  :integer          default("other"), not null
#  cover_image_preset        :string
#  description               :text
#  discord_synced_at         :datetime
#  ends_at                   :datetime
#  excluded_dates            :date             default([]), not null, is an Array
#  external_uid              :uuid             not null
#  location                  :string
#  max_attendees             :integer
#  meetup_location           :string
#  recurrence_count          :integer
#  recurrence_interval       :string
#  recurrence_until          :date
#  recurring                 :boolean          default(FALSE), not null
#  scenario                  :string
#  signup_approval           :string           default("direct"), not null
#  slug                      :string           not null
#  starting_soon_notified_at :datetime
#  starts_at                 :datetime         not null
#  status                    :string           default("draft"), not null
#  timezone                  :string           default("UTC"), not null
#  title                     :string           not null
#  visibility                :string           default("members"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  created_by_id             :uuid             not null
#  discord_event_id          :string
#  discord_message_id        :string
#  fleet_id                  :uuid             not null
#  mission_id                :uuid
#
# Indexes
#
#  index_fleet_events_on_external_uid            (external_uid) UNIQUE
#  index_fleet_events_on_fleet_id_and_recurring  (fleet_id,recurring)
#  index_fleet_events_on_fleet_id_and_slug       (fleet_id,slug) UNIQUE
#  index_fleet_events_on_fleet_id_and_starts_at  (fleet_id,starts_at)
#  index_fleet_events_on_fleet_id_and_status     (fleet_id,status)
#  index_fleet_events_on_mission_id              (mission_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (mission_id => missions.id)
#
FactoryBot.define do
  factory :fleet_event do
    fleet
    association :created_by, factory: :user
    sequence(:title) { |n| "Event #{n}" }
    description { Faker::Lorem.sentence }
    starts_at { 1.day.from_now }
    timezone { "UTC" }
    visibility { "members" }
    category { "other" }

    trait :open do
      status { "open" }
    end

    trait :locked do
      status { "locked" }
    end

    trait :active do
      status { "active" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end

  factory :fleet_event_team do
    fleet_event
    sequence(:title) { |n| "Team #{n}" }
    sequence(:position) { |n| n }
  end

  factory :fleet_event_ship do
    fleet_event_team
    sequence(:position) { |n| n }
    classification { "Combat" }

    trait :strict do
      classification { nil }
      association :model, in_game: true
    end
  end

  factory :fleet_event_slot do
    title { "Pilot" }
    sequence(:position) { |n| n }
    association :slottable, factory: :fleet_event_team

    trait :for_team do
      association :slottable, factory: :fleet_event_team
    end

    trait :for_ship do
      association :slottable, factory: :fleet_event_ship
    end
  end

  factory :fleet_event_signup do
    association :fleet_event_slot
    fleet_membership
    status { "confirmed" }
  end
end
