FactoryBot.define do
  factory :model_paint do
    name { Faker::Name.name }
    model
    hidden { false }
    active { true }

    trait :hidden do
      hidden { true }
    end

    trait :on_sale do
      on_sale { true }
      pledge_price { 10.0 }
    end

    trait :with_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/ship.jpg"), "image/jpeg") }
    end

    trait :with_fleetchart_image do
      fleetchart_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :with_rsi_data do
      rsi_id { Faker::Number.number(digits: 5) }
      rsi_name { name }
      rsi_slug { name.parameterize }
    end
  end
end
