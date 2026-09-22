# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
#
#  id               :uuid             not null, primary key
#  body             :text             not null
#  discord_parts    :text             default([]), not null, is an Array
#  icon             :string
#  last_tested_at   :datetime
#  link             :string
#  notify_users     :boolean          default(TRUE), not null
#  post_bluesky     :boolean          default(FALSE), not null
#  post_discord     :boolean          default(FALSE), not null
#  post_x           :boolean          default(FALSE), not null
#  publish_at       :datetime
#  published_at     :datetime
#  recipients_count :integer
#  social_parts     :text             default([]), not null, is an Array
#  status           :string           default("draft"), not null
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin_user_id    :uuid
#
# Indexes
#
#  index_announcements_on_publish_at    (publish_at) WHERE ((status)::text = 'scheduled'::text)
#  index_announcements_on_published_at  (published_at DESC)
#  index_announcements_on_status        (status)
#
# Foreign Keys
#
#  fk_rails_...  (admin_user_id => admin_users.id)
#
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
