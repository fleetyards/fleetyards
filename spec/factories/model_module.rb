FactoryBot.define do
  factory :model_module do
    name { Faker::Name.name }
    active { true }
    hidden { false }
  end
end
