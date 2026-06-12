# == Schema Information
#
# Table name: model_hardpoint_loadouts
#
#  id                 :uuid             not null, primary key
#  name               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  component_id       :uuid
#  model_hardpoint_id :uuid
#
FactoryBot.define do
  factory :model_hardpoint_loadout do
    name { Faker::Lorem.word }
    model_hardpoint
  end
end
