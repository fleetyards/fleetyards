# frozen_string_literal: true

FactoryBot.define do
  factory :friendship do
    association :requester, factory: :user
    association :addressee, factory: :user

    trait :accepted do
      aasm_state { "accepted" }
      accepted_at { Time.zone.now }
    end

    trait :declined do
      aasm_state { "declined" }
      declined_at { Time.zone.now }
    end

    trait :ignored do
      aasm_state { "ignored" }
      ignored_at { Time.zone.now }
    end
  end
end
