# frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    user
    message { "The planner is great, but dragging is slow." }

    trait :resolved do
      aasm_state { "resolved" }
      resolved_at { Time.current }
    end
  end
end
