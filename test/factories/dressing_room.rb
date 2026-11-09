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

    trait :with_face_library do
      face_library { "male-6a268db0" }
      face_index { Rack::Test::UploadedFile.new(StringIO.new("{}"), "application/json", original_filename: "index.json") }
      face_positions { Rack::Test::UploadedFile.new(StringIO.new("\0" * 8), "application/octet-stream", original_filename: "library.bin") }
      face_normals { Rack::Test::UploadedFile.new(StringIO.new("\0" * 8), "application/octet-stream", original_filename: "normals.bin") }
    end
  end

  factory :character_face do
    user
    sequence(:name) { |n| "Character #{n}" }

    transient do
      fixture { "Macken" }
    end

    after(:build) do |face, evaluator|
      face.file = Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/chf/#{evaluator.fixture}.chf"), "application/octet-stream")
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
