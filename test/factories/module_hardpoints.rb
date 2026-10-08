FactoryBot.define do
  factory :module_hardpoint do
    model
    model_module

    trait :with_slot do
      slot { "hardpoint_module" }
    end
  end
end
