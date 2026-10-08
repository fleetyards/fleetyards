# frozen_string_literal: true

FactoryBot.define do
  factory :blueprint_cost_option do
    slot factory: :blueprint_cost_slot
    commodity
    commodity_key { "items_commodities_iron" }
    cost_type { "resource" }
    quantity { 0.03 }
    min_quality { 0 }
    position { 0 }

    trait :item do
      cost_type { "item" }
      quantity { 2 }
    end
  end
end
