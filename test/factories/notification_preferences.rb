# frozen_string_literal: true

FactoryBot.define do
  factory :notification_preference do
    user
    notification_type { "hangar_sync_finished" }
    app { true }
    mail { false }
    push { false }

    trait :mail_enabled do
      mail { true }
    end

    trait :app_disabled do
      app { false }
    end

    trait :model_on_sale do
      notification_type { "model_on_sale" }
    end
  end
end
