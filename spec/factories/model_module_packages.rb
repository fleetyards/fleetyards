FactoryBot.define do
  factory :model_module_package do
    name { Faker::Name.name }
    model_modules { create_list(:model_module, 2) }
    model
    active { true }
    hidden { false }
  end
end
