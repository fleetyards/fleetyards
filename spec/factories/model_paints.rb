FactoryBot.define do
  factory :model_paint do
    name { Faker::Name.name }
    model
    hidden { false }
    active { true }
  end
end
