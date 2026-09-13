# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_contract do
    fleet
    association :created_by, factory: :user
    sequence(:title) { |n| "Contract #{n}" }
    description { Faker::Lorem.sentence }
    kind { :procurement }
    reward { 120_000 }

    destination_fleet_inventory do
      association(:fleet_inventory, fleet: fleet)
    end

    trait :transport do
      kind { :transport }
      source_fleet_inventory do
        association(:fleet_inventory, fleet: fleet)
      end
    end

    trait :crafting do
      kind { :crafting }
    end

    trait :with_item do
      after(:create) do |contract|
        create(:fleet_contract_item, fleet_contract: contract)
      end
    end

    trait :published do
      with_item
      aasm_state { "open" }
      published_at { Time.current }
    end

    trait :in_progress do
      with_item
      aasm_state { "in_progress" }
      published_at { Time.current }
      claimed_at { Time.current }
    end
  end
end
