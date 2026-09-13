# frozen_string_literal: true

# == Schema Information
#
# Table name: tours
#
#  id            :uuid             not null, primary key
#  cancelled_at  :datetime
#  description   :text
#  invite_token  :string           not null
#  settled_at    :datetime
#  slug          :string           not null
#  starts_at     :datetime
#  status        :string           default("open"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :uuid             not null
#
# Indexes
#
#  index_tours_on_created_by_id_and_status  (created_by_id,status)
#  index_tours_on_invite_token              (invite_token) UNIQUE
#  index_tours_on_slug                      (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#
FactoryBot.define do
  factory :tour do
    association :created_by, factory: :user
    sequence(:title) { |n| "Tour #{n}" }
    description { Faker::Lorem.sentence }
    starts_at { 1.day.from_now }

    trait :settled do
      status { "settled" }
      settled_at { Time.current }
    end

    trait :cancelled do
      status { "cancelled" }
      cancelled_at { Time.current }
    end
  end
end
