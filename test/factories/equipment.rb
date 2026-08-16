# frozen_string_literal: true

FactoryBot.define do
  factory :equipment do
    sequence(:name) { |n| "#{Faker::Company.name} Rifle #{n}" }
    sequence(:sc_key) { |n| "test_rifle_ballistic_#{n}" }
    equipment_type { "weapon" }
    item_type { "assault_rifle" }
    weapon_class { "ballistic" }
    sub_type { "Medium" }
    size { "2" }
    hidden { false }

    trait :attachment do
      equipment_type { "weapon_attachment" }
      item_type { "weapon_scope" }
      weapon_class { nil }
      sub_type { "IronSight" }
    end

    trait :magazine do
      equipment_type { "weapon_attachment" }
      item_type { "magazine" }
      weapon_class { nil }
      sub_type { "Magazine" }
      storage { 40 }
    end

    trait :hidden do
      hidden { true }
    end
  end
end
