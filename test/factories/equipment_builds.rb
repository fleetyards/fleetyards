# == Schema Information
#
# Table name: equipment_builds
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  environment            :string           not null
#  equipment_type         :string
#  g_force_tolerance      :decimal(15, 2)
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  item_type              :string
#  name                   :string
#  radiation_protection   :decimal(15, 2)
#  radiation_scrub_rate   :decimal(15, 2)
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  size                   :string
#  slot                   :integer
#  storage                :decimal(15, 2)
#  sub_type               :string
#  temperature_rating     :string
#  version                :string           not null
#  volume                 :decimal(15, 6)
#  volume_dimensions      :jsonb
#  weapon_class           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  equipment_id           :uuid             not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_builds_on_environment_and_equipment_type  (environment,equipment_type)
#  index_equipment_builds_on_environment_and_item_type       (environment,item_type)
#  index_equipment_builds_on_environment_and_version         (environment,version)
#  index_equipment_builds_on_equipment_and_build             (equipment_id,environment,version) UNIQUE
#  index_equipment_builds_on_equipment_id                    (equipment_id)
#  index_equipment_builds_on_manufacturer_id                 (manufacturer_id)
#
# Foreign Keys
#
#  fk_rails_...  (equipment_id => equipment.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :equipment_build do
    association :equipment, factory: [:equipment, :without_build]
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    sequence(:name) { |n| "#{Faker::Company.name} Rifle #{n}" }
    equipment_type { "weapon" }
    item_type { "assault_rifle" }
    size { "2" }
    hidden { false }
  end
end
