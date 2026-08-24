# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_notifications
#
#  id                :uuid             not null, primary key
#  archived_at       :datetime
#  body              :text
#  dedupe_key        :string
#  expires_at        :datetime         not null
#  icon              :string
#  last_occurred_at  :datetime         not null
#  link              :string
#  notification_type :string           not null
#  occurrences       :integer          default(1), not null
#  read_at           :datetime
#  record_type       :string
#  severity          :string           default("info"), not null
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  admin_user_id     :uuid             not null
#  record_id         :uuid
#
# Indexes
#
#  index_admin_notifications_on_admin_user_id_and_archived_at  (admin_user_id,archived_at)
#  index_admin_notifications_on_admin_user_id_and_created_at   (admin_user_id,created_at DESC)
#  index_admin_notifications_on_admin_user_id_and_read_at      (admin_user_id,read_at)
#  index_admin_notifications_on_dedupe                         (admin_user_id,notification_type,dedupe_key) UNIQUE WHERE ((read_at IS NULL) AND (archived_at IS NULL) AND (dedupe_key IS NOT NULL))
#  index_admin_notifications_on_expires_at                     (expires_at)
#  index_admin_notifications_on_notification_type              (notification_type)
#  index_admin_notifications_on_record                         (record_type,record_id)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id) ON DELETE => cascade
#
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

    trait :archived do
      archived_at { Time.current }
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
