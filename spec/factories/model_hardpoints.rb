# == Schema Information
#
# Table name: model_hardpoints
#
#  id                 :uuid             not null, primary key
#  category           :integer
#  deleted_at         :datetime
#  details            :string
#  group              :integer
#  hardpoint_type     :integer
#  item_slot          :integer
#  item_slots         :integer
#  key                :string
#  loadout_identifier :string
#  mount              :string
#  name               :string
#  size               :integer
#  source             :integer
#  sub_category       :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  component_id       :uuid
#  model_id           :uuid
#
# Indexes
#
#  index_model_hardpoints_on_component_id  (component_id)
#  index_model_hardpoints_on_model_id      (model_id)
#
FactoryBot.define do
  factory :model_hardpoint do
    source { ModelHardpoint.sources.keys.sample }
    key { Faker::Alphanumeric.alphanumeric(number: 10) }
    hardpoint_type { ModelHardpoint.hardpoint_types.keys.sample }
    group { ModelHardpoint.groups.keys.sample }
    model
  end
end
