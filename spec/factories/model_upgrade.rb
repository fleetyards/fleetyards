FactoryBot.define do
  factory :model_upgrade do
    name { Faker::Name.name }
    models { create_list(:model, 2) }
    active { true }
    hidden { false }
  end
end
