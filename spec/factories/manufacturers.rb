FactoryBot.define do
  factory :manufacturer do
    name { Faker::Name.name }
    code { Faker::Name.initials(number: 4) }
    logo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    long_name { name }
    sc_ref { name.parameterize }

    trait :with_models do
      transient do
        models_count { 5 }
      end

      after(:create) do |manufacturer, evaluator|
        create_list(:model, evaluator.models_count, manufacturer: manufacturer)
      end
    end
  end
end
