# frozen_string_literal: true

FactoryBot.define do
  factory :character_body do
    sequence(:key) { |n| "body_#{n}" }

    trait :with_holo do
      holo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/holo/plain.glb"), "model/gltf-binary") }
    end

    trait :with_textured_holo do
      holo_textured { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/holo/plain.glb"), "model/gltf-binary") }
    end
  end

  factory :outfit do
    user
    sequence(:name) { |n| "Outfit #{n}" }
  end

  factory :worn_equipment, class: "Equipment", parent: :equipment do
    equipment_type { "armor" }
    item_type { nil }
    weapon_class { nil }
    sub_type { "Heavy" }
    size { nil }
    slot { "torso" }
  end
end
