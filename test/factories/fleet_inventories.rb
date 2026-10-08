# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_inventory do
    fleet
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 2)} #{n}" }
    description { Faker::Lorem.sentence }
    visibility { :members_only }

    trait :officers_only do
      visibility { :officers_only }
    end

    trait :with_manager do
      association :manager, factory: :user

      after(:build) do |inventory|
        create(:fleet_membership, :accepted, fleet: inventory.fleet, user: inventory.manager)
      end
    end
  end
end
