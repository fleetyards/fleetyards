# frozen_string_literal: true

FactoryBot.define do
  factory :model_position do
    model
    name { "Pilot" }
    position_type { :pilot }
    source { :sc_data }
    position { 0 }

    trait :copilot do
      name { "Copilot" }
      position_type { :copilot }
      position { 1 }
    end

    trait :turret_gunner do
      name { "Turret Gunner" }
      position_type { :turret_gunner }
      position { 2 }
    end

    trait :engineer do
      name { "Engineer" }
      position_type { :engineer }
      position { 3 }
    end

    trait :loadmaster do
      name { "Loadmaster" }
      position_type { :loadmaster }
      position { 4 }
    end

    trait :curated do
      source { :curated }
    end

    trait :passenger do
      name { "Passenger" }
      position_type { :passenger }
      source { :curated }
    end
  end
end
