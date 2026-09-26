# frozen_string_literal: true

FactoryBot.define do
  factory :terminal do
    sequence(:uex_id) { |n| 10_000 + n }
    sequence(:name) { |n| "Terminal #{n}" }
    star_system { "Stanton" }
    max_container_size { 32 }
    available { true }
  end
end
