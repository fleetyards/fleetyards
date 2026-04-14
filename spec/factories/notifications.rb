# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :uuid             not null, primary key
#  body              :text
#  expires_at        :datetime         not null
#  icon              :string
#  link              :string
#  notification_type :string           not null
#  read_at           :datetime
#  record_type       :string
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  record_id         :uuid
#  user_id           :uuid             not null
#
# Indexes
#
#  index_notifications_on_expires_at              (expires_at)
#  index_notifications_on_notification_type       (notification_type)
#  index_notifications_on_record                  (record_type,record_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at DESC)
#  index_notifications_on_user_id_and_read_at     (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :hangar_sync do
      notification_type { "hangar_sync_finished" }
      title { "Hangar sync completed" }
    end
  end
end
