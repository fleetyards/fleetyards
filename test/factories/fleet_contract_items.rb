# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_contract_item do
    fleet_contract
    name { Faker::Commerce.product_name }
    category { :commodity }
    unit { :scu }
    quantity { 100 }
    reward_rate { fleet_contract&.reward_per_unit? ? 10 : nil }

    trait :component do
      category { :component }
      unit { :units }
    end

    trait :graded do
      quality { 500 }
    end
  end
end
