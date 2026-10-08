# frozen_string_literal: true

FactoryBot.define do
  factory :push_subscription do
    user
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/device-#{n}" }
    p256dh_key { "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM" }
    auth_key { "tBHItJI5svbpez7KI4CCXg" }
    user_agent { "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0" }
  end
end
