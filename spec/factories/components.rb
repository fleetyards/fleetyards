FactoryBot.define do
  factory :component do
    name { Faker::Name.name }
  end
end
