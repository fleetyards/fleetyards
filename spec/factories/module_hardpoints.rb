# == Schema Information
#
# Table name: module_hardpoints
#
#  id              :uuid             not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_id        :uuid
#  model_module_id :uuid
#
FactoryBot.define do
  factory :module_hardpoint do
    model
    model_module
  end
end
