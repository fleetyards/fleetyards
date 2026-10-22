FactoryBot.define do
  factory :hangar_plan do
    user
    sequence(:name) { |n| "Plan #{n}" }
  end

  factory :hangar_plan_slot do
    hangar_plan
    sequence(:label) { |n| "Slot #{n}" }
    quantity { 1 }
  end

  factory :hangar_plan_candidate do
    association :slot, factory: :hangar_plan_slot
    model
  end

  factory :hangar_plan_melt do
    hangar_plan
    vehicle { association :vehicle, user: hangar_plan.user }
  end
end
