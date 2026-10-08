# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_squadron do
    fleet
    sequence(:name) { |n| "#{Faker::Military.air_force_rank} Wing #{n}" }
    short_description { Faker::Lorem.sentence }

    trait :with_color do
      color { "#ff8800" }
    end

    trait :with_icon do
      icon { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end
  end
end
