# frozen_string_literal: true

# == Schema Information
#
# Table name: missions
#
#  id            :uuid             not null, primary key
#  archived_at   :datetime
#  category      :integer          default("other"), not null
#  description   :text
#  scenario      :string
#  slug          :string           not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :uuid             not null
#  fleet_id      :uuid             not null
#
# Indexes
#
#  index_missions_on_fleet_id_and_archived_at  (fleet_id,archived_at)
#  index_missions_on_fleet_id_and_category     (fleet_id,category)
#  index_missions_on_fleet_id_and_scenario     (fleet_id,scenario)
#  index_missions_on_fleet_id_and_slug         (fleet_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#
FactoryBot.define do
  factory :mission do
    fleet
    association :created_by, factory: :user
    sequence(:title) { |n| "Mission #{n}" }
    description { Faker::Lorem.sentence }

    trait :archived do
      archived_at { Time.current }
    end
  end

  factory :mission_team do
    mission
    sequence(:title) { |n| "Team #{n}" }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
  end

  factory :mission_ship do
    mission_team
    sequence(:position) { |n| n }
    classification { "Combat" }

    trait :strict do
      classification { nil }
      association :model, in_game: true
    end

    trait :ranged do
      classification { "Combat" }
      min_size { "medium" }
    end
  end

  factory :mission_slot do
    title { "Pilot" }
    description { Faker::Lorem.sentence }
    sequence(:position) { |n| n }
    association :slottable, factory: :mission_team

    trait :for_team do
      association :slottable, factory: :mission_team
    end

    trait :for_ship do
      association :slottable, factory: :mission_ship
    end
  end
end
