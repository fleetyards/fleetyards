FactoryBot.define do
  factory :dock do
    name { Faker::Name.name }
    dock_type { :hangar }
    ship_size { :small }

    # A dock always belongs to something, and a ship is the common case. Pass
    # `parent:` a ModelModule for the other one.
    parent { association(:model) }

    trait :with_dimensions do
      beam { 25.0 }
      height { 15.0 }
      length { 50.0 }
    end

    trait :vehiclepad do
      dock_type { :vehiclepad }
    end

    trait :garage do
      dock_type { :garage }
    end
  end
end
