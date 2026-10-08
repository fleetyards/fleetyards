FactoryBot.define do
  factory :manufacturer do
    name { Faker::Name.name }
    code { Faker::Name.initials(number: 4) }
    long_name { name }
    sc_ref { name.parameterize }

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_icon do
      icon_path { "ui/sharedassets/manufacturerlogos/test_256.tif" }
      icon { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_description do
      description { Faker::Lorem.paragraph }
      known_for { Faker::Lorem.sentence }
    end

    trait :with_rsi_data do
      rsi_id { Faker::Number.number(digits: 5) }
    end

    trait :with_models do
      transient do
        models_count { 1 }
      end

      after(:create) do |manufacturer, evaluator|
        create_list(:model, evaluator.models_count, manufacturer: manufacturer)
      end
    end
  end
end
