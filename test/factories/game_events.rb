# frozen_string_literal: true

FactoryBot.define do
  factory :game_event do
    sequence(:title) { |n| "Game event ##{n}" }
    starts_at { 2.days.from_now }
    ends_at { 9.days.from_now }
    category { :other }
    published { true }

    trait :draft do
      published { false }
    end

    trait :past do
      starts_at { 10.days.ago }
      ends_at { 3.days.ago }
    end
  end
end
