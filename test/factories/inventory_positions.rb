# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_position do
    inventory
    name { Faker::Commerce.product_name }
    category { :commodity }
    unit { :scu }

    trait :component do
      category { :component }
      unit { :units }
    end
  end
end
