FactoryBot.define do
  factory :vehicle do
    model
    user

    trait :with_name do
      name { Faker::Name.name }
    end
  end
end
