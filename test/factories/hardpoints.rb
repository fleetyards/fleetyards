# == Schema Information
#
# Table name: hardpoints
#
#  id           :uuid             not null, primary key
#  category     :integer
#  details      :string
#  group        :integer
#  group_key    :string
#  matrix_key   :string
#  max_size     :integer
#  min_size     :integer
#  parent_type  :string           not null
#  sc_name      :string
#  source       :integer
#  types        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  component_id :uuid
#  parent_id    :uuid             not null
#
# Indexes
#
#  index_hardpoints_on_component_id  (component_id)
#  index_hardpoints_on_parent        (parent_type,parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id)
#
FactoryBot.define do
  factory :hardpoint do
    source { Hardpoint.sources.keys.sample }
    sc_name { Faker::Alphanumeric.alphanumeric(number: 10) }
    association :parent, factory: :model
  end
end
