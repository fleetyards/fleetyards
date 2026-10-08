FactoryBot.define do
  factory :fleet_role do
    fleet
    name { "Member" }
    resource_access { FleetRole.preset_privileges[:member] }
    permanent { false }

    trait :admin do
      name { "Admin" }
      resource_access { FleetRole.preset_privileges[:admin] }
      permanent { true }
    end

    trait :officer do
      name { "Officer" }
      resource_access { FleetRole.preset_privileges[:officer] }
    end

    trait :member do
      name { "Member" }
      resource_access { FleetRole.preset_privileges[:member] }
    end
  end
end
