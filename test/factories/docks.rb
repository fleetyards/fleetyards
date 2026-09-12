# == Schema Information
#
# Table name: docks
#
#  id            :uuid             not null, primary key
#  beam          :decimal(15, 2)
#  dock_type     :integer
#  group         :string
#  height        :decimal(15, 2)
#  length        :decimal(15, 2)
#  max_ship_size :integer
#  min_ship_size :integer
#  name          :string
#  parent_type   :string           not null
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid
#  parent_id     :uuid             not null
#
# Indexes
#
#  index_docks_on_parent_type_and_parent_id  (parent_type,parent_id)
#
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
