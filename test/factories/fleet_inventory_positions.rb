# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_inventory_position do
    fleet_inventory
    name { Faker::Commerce.product_name }
    category { :commodity }
    unit { :scu }

    trait :component do
      category { :component }
      unit { :units }
    end
  end
end
