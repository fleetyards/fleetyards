# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    user
    notification_type { "hangar_create" }
    title { "Vehicle added to hangar" }
    body { nil }
    link { nil }
    icon { nil }

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end

    trait :archived do
      archived_at { Time.current }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :hangar_sync do
      notification_type { "hangar_sync_finished" }
      title { "Hangar sync completed" }
    end
  end
end
