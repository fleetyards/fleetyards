# frozen_string_literal: true

FactoryBot.define do
  factory :fleet_contract_assignment do
    fleet_contract
    user
    role { :crew }

    trait :lead do
      role { :lead }
      aasm_state { "accepted" }
      accepted_at { Time.current }
    end

    trait :accepted do
      aasm_state { "accepted" }
      accepted_at { Time.current }
    end
  end
end
