FactoryBot.define do
  factory :image do
    file { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/image.jpg"), "image/jpeg") }
    gallery { Model.order(:created_at).first || create(:model) }
    enabled { true }
    global { true }

    trait :disabled do
      enabled { false }
    end

    trait :private do
      global { false }
    end

    trait :no_background do
      background { false }
    end
  end
end
