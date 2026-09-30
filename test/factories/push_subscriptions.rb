# frozen_string_literal: true

# == Schema Information
#
# Table name: push_subscriptions
#
#  id                :uuid             not null, primary key
#  auth_key          :string           not null
#  endpoint          :string           not null
#  failure_count     :integer          default(0), not null
#  last_delivered_at :datetime
#  last_failed_at    :datetime
#  p256dh_key        :string           not null
#  user_agent        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :uuid             not null
#
# Indexes
#
#  index_push_subscriptions_on_endpoint  (endpoint) UNIQUE
#  index_push_subscriptions_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :push_subscription do
    user
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/device-#{n}" }
    p256dh_key { "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM" }
    auth_key { "tBHItJI5svbpez7KI4CCXg" }
    user_agent { "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0" }
  end
end
