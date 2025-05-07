FactoryBot.define do
  factory :dock do
    name { Faker::Name.name }
    dock_type { :hangar }
    ship_size { :small }
  end
end
