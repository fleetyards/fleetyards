# frozen_string_literal: true

FactoryBot.define do
  factory :tour_join_request do
    association :tour, factory: [:tour, :for_fleet]
    association :user, factory: :user

    trait :approved do
      aasm_state { "approved" }
      decided_at { Time.current }
    end

    trait :declined do
      aasm_state { "declined" }
      decided_at { Time.current }
    end
  end
end
