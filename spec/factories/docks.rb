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
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid
#
FactoryBot.define do
  factory :dock do
    name { Faker::Name.name }
    dock_type { :hangar }
    ship_size { :small }
  end
end
