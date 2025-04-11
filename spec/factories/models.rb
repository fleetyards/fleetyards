FactoryBot.define do
  factory :model do
    name { Faker::Name.name }
    beam { 27.75 }
    cargo { 96 }
    classification { :multi_role }
    size { :large }
    height { 15.25 }
    hidden { false }
    images_count { 0 }
    last_pledge_price { 225 }
    length { 63.5 }
    manufacturer
    mass { 430057.0 }
    max_crew { 4 }
    min_crew { 3 }
    model_paints_count { 0 }
    module_hardpoints_count { 0 }
    rsi_chassis_id { 45 }
    rsi_id { 45 }
    upgrade_kits_count { 0 }
    videos_count { 0 }
    ground { false }
    hydrogen_fuel_tank_size { 660000.0 }
    quantum_fuel_tank_size { 3000.0 }
    scm_speed { 144.0 }
    max_speed { 911.0 }
    scm_speed_acceleration { 3.11 }
    scm_speed_decceleration { 6.22 }
    max_speed_acceleration { 19.66 }
    max_speed_decceleration { 39.35 }
    pitch { 25.0 }
    yaw { 25.0 }
    roll { 65.0 }

    trait :with_images do
      after(:create) do |model|
        create_list(:image, 3, gallery: model)
      end
    end

    trait :with_videos do
      after(:create) do |model|
        create_list(:video, 3, model: model)
      end
    end

    trait :with_hardpoints do
      after(:create) do |model|
        create_list(:model_hardpoint, 3, model: model)
      end
    end

    trait :with_upgrades do
      after(:create) do |model|
        create_list(:model_upgrade, 3, models: [model])
      end
    end

    trait :with_snub_crafts do
      after(:create) do |model|
        create_list(:model_snub_craft, 3, model: model)
      end
    end

    trait :with_paints do
      after(:create) do |model|
        create_list(:model_paint, 3, model: model)
      end
    end

    trait :with_modules do
      after(:create) do |model|
        create_list(:module_hardpoint, 3, model: model)
      end
    end

    trait :with_module_packages do
      after(:create) do |model|
        create_list(:model_module_package, 3, model: model)
      end
    end

    trait :with_loaners do
      after(:create) do |model|
        create_list(:model_loaner, 3, model: model)
      end
    end

    trait :with_legacy_images do
      fleetchart_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/jpeg") }
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/jpeg") }
    end
  end
end
