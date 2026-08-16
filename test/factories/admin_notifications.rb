# frozen_string_literal: true

FactoryBot.define do
  factory :admin_notification do
    admin_user
    notification_type { "paints_import" }
    severity { "info" }
    title { "Paints Import Results" }
    body { nil }
    link { nil }
    icon { nil }

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :actionable do
      severity { "warning" }
      body { "## Missing Models (1)\n\n- **Aurora MR**" }
    end
  end
end
