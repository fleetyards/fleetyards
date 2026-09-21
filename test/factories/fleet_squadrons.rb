# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_squadron do
    fleet
    sequence(:name) { |n| "#{Faker::Military.air_force_rank} Wing #{n}" }
    description { Faker::Lorem.sentence }

    trait :with_color do
      color { "#ff8800" }
    end

    trait :with_logo do
      logo { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end
  end
end
