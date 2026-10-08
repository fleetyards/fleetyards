# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_item do
    inventory
    name { Faker::Commerce.product_name }
    category { :commodity }
    quantity { rand(1..100) }
    unit { :scu }

    trait :with_notes do
      notes { Faker::Lorem.sentence }
    end

    trait :component do
      category { :component }
      unit { :units }
    end
  end
end
