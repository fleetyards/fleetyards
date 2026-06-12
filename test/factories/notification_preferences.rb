# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_preferences
#
#  id                :uuid             not null, primary key
#  app               :boolean          default(TRUE), not null
#  mail              :boolean          default(FALSE), not null
#  notification_type :string           not null
#  push              :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  idx_on_user_id_notification_type_2ab4363e9b  (user_id,notification_type) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :notification_preference do
    user
    notification_type { "hangar_create" }
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
