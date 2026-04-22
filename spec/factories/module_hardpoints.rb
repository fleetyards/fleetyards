# == Schema Information
#
# Table name: module_hardpoints
#
#  id              :uuid             not null, primary key
#  slot            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_id        :uuid
#  model_module_id :uuid
#
# Indexes
#
#  index_module_hardpoints_on_model_id_and_slot  (model_id,slot)
#
FactoryBot.define do
  factory :module_hardpoint do
    model
    model_module

    trait :with_slot do
      slot { "hardpoint_module" }
    end
  end
end
