FactoryBot.define do
  factory :fleet_membership do
    fleet
    user
    fleet_role { fleet.fleet_roles.ranked.last }

    trait :invited do
      aasm_state { :invited }
      invited_at { Time.zone.now }
    end

    trait :accepted do
      aasm_state { :accepted }
      accepted_at { Time.zone.now }
    end

    trait :requested do
      aasm_state { :requested }
      requested_at { Time.zone.now }
    end

    trait :declined do
      aasm_state { :declined }
      declined_at { Time.zone.now }
    end

    trait :primary do
      primary { true }
    end

    trait :hide_ships do
      hide_ships { true }
      ships_filter { :hide }
    end

    trait :with_nickname do
      nickname { "Wingman" }
    end

    trait :as_admin do
      fleet_role { fleet.fleet_roles.ranked.first }
    end

    trait :as_officer do
      fleet_role { fleet.fleet_roles.ranked.second }
    end
  end
end
