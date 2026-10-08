# frozen_string_literal: true

FactoryBot.define do
  factory :exchange_rate do
    from_currency { "USD" }
    to_currency { "EUR" }
    rate { 0.92 }
    fetched_at { Time.current }
  end
end
