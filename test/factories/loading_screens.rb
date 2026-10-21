# frozen_string_literal: true

FactoryBot.define do
  factory :loading_screen do
    environment { "live" }
    version { "1.0.0-live.1" }
    sequence(:name) { |n| "loadingscreen_#{n}.png" }

    trait :with_image do
      image { {io: File.open(Rails.root.join("test/fixtures/files/test.png")), filename: name, content_type: "image/png"} }
    end
  end
end
