# frozen_string_literal: true

FactoryBot.define do
  factory :blueprint_cost_slot do
    blueprint
    sequence(:position) { |n| n }
    sc_key { "frame" }
    name { "Frame" }

    trait :with_option do
      after(:create) do |slot|
        create(:blueprint_cost_option, slot:)
      end
    end
  end
end
