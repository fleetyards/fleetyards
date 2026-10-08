FactoryBot.define do
  factory :model do
    name { Faker::Name.name }
    beam { 27.75 }
    cargo { 96 }
    classification { :multi_role }
    focus { :combat }
    size { :large }
    height { 15.25 }
    active { true }
    hidden { false }
    images_count { 0 }
    pledge_price { 225 }
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

    # `in_game?` reads a build row rather than a column, so this is what puts a
    # ship in the game. No hook by default: 31 of 246 models in a real catalogue
    # are concept ships with no build, and that is the more common case.
    trait :in_game do
      after(:create) do |model|
        model.builds.create!(
          environment: ScData::Source.environment,
          version: ScData::Source.version
        )

        model.association(:build).reset
        model.association(:last_build).reset
      end
    end
    hydrogen_fuel_tank_size { 660000.0 }
    quantum_fuel_tank_size { 3000.0 }
    scm_speed { 144.0 }
    max_speed { 911.0 }
    main_acceleration { 61.09 }
    retro_acceleration { 30.55 }
    pitch { 25.0 }
    yaw { 25.0 }
    roll { 65.0 }

    trait :with_images do
      after(:create) do |model|
        create_list(:image, 3, gallery: model, file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg"))
      end
    end

    trait :with_videos do
      after(:create) do |model|
        create_list(:video, 3, model: model)
      end
    end

    trait :with_hardpoints do
      after(:create) do |model|
        create_list(:hardpoint, 3, parent: model)
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

    trait :with_variants do
      after(:create) do |model|
        create_list(:model, 3, base_model_id: model.id)
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
      fleetchart_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/ship.jpg"), "image/jpeg") }
    end

    trait :with_docks do
      after(:create) do |model|
        create_list(:dock, 3, parent: model)
      end
    end

    trait :hidden do
      hidden { true }
    end

    trait :inactive do
      active { false }
    end

    trait :ground_vehicle do
      ground { true }
      ground_max_speed { 50.0 }
      ground_acceleration { 5.0 }
      ground_deceleration { 10.0 }
      ground_reverse_speed { 25.0 }
    end

    trait :with_description do
      description { Faker::Lorem.paragraph }
      production_status { "flight-ready" }
      production_note { "Available now" }
    end

    trait :on_sale do
      on_sale { true }
    end

    trait :with_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/ship.jpg"), "image/jpeg") }
    end

    trait :with_fleetchart_image do
      fleetchart_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_brochure do
      brochure { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end
  end
end
