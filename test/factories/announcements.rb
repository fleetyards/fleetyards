# frozen_string_literal: true

FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "Announcement ##{n}" }
    body { "Something **new** just landed." }
    notify_users { true }

    trait :scheduled do
      status { "scheduled" }
      publish_at { 1.hour.from_now }
    end

    trait :published do
      status { "published" }
      published_at { Time.current }
    end

    trait :failed do
      status { "failed" }
    end

    trait :social do
      post_discord { true }
      post_bluesky { true }
      post_x { true }
    end

    trait :with_link do
      link { "/fleets/" }
    end
  end

  factory :announcement_delivery do
    announcement
    channel { "discord" }
    status { "pending" }
  end
end
