# frozen_string_literal: true

FactoryBot.define do
  factory :cargo_hold do
    association :parent, factory: :model
    name { "cargo_hold_#{SecureRandom.hex(4)}" }
    dimension_x { 5.0 }
    dimension_y { 2.5 }
    dimension_z { 2.5 }
    capacity_scu { 8 }
    max_container_size_scu { 8 }
    position { 0 }

    trait :for_module do
      association :parent, factory: :model_module
    end
  end
end
