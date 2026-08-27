# == Schema Information
#
# Table name: component_builds
#
#  id                    :uuid             not null, primary key
#  ammunition            :string
#  category              :string
#  component_class       :string
#  component_sub_type    :string
#  component_type        :string
#  description           :text
#  durability            :string
#  environment           :string           not null
#  grade                 :string
#  heat_connection       :string
#  hidden                :boolean          default(FALSE)
#  inventory_consumption :string
#  item_class            :integer
#  item_type             :string
#  name                  :string
#  power_connection      :string
#  size                  :string
#  tracking_signal       :integer
#  type_data             :string
#  version               :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  component_id          :uuid             not null
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_component_builds_on_component_and_build              (component_id,environment,version) UNIQUE
#  index_component_builds_on_component_id                     (component_id)
#  index_component_builds_on_environment_and_component_class  (environment,component_class)
#  index_component_builds_on_environment_and_item_type        (environment,item_type)
#  index_component_builds_on_environment_and_version          (environment,version)
#  index_component_builds_on_manufacturer_id                  (manufacturer_id)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :component_build do
    association :component, factory: [:component, :without_build]
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    sequence(:name) { |n| "#{Faker::Company.name} Shield #{n}" }
    component_class { "Shield" }
    item_type { "Shield" }
    size { "2" }
    grade { "A" }
    hidden { false }
  end
end
