# frozen_string_literal: true

# == Schema Information
#
# Table name: equipment
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  equipment_type         :string
#  extras                 :string
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  icon                   :string
#  item_type              :string
#  name                   :string
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  sc_key                 :string
#  sc_ref                 :string
#  size                   :string
#  slot                   :integer
#  slug                   :string
#  storage                :decimal(15, 2)
#  store_image            :string
#  store_image_height     :integer
#  store_image_width      :integer
#  sub_type               :string
#  temperature_rating     :string
#  version                :string
#  volume                 :decimal(15, 2)
#  weapon_class           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_on_equipment_type   (equipment_type)
#  index_equipment_on_item_type        (item_type)
#  index_equipment_on_manufacturer_id  (manufacturer_id)
#  index_equipment_on_sc_key           (sc_key) UNIQUE
#
FactoryBot.define do
  factory :equipment do
    sequence(:name) { |n| "#{Faker::Company.name} Rifle #{n}" }
    sequence(:sc_key) { |n| "test_rifle_ballistic_#{n}" }
    equipment_type { "weapon" }
    item_type { "assault_rifle" }
    weapon_class { "ballistic" }
    sub_type { "Medium" }
    size { "2" }
    hidden { false }

    trait :attachment do
      equipment_type { "weapon_attachment" }
      item_type { "weapon_scope" }
      weapon_class { nil }
      sub_type { "IronSight" }
    end

    trait :magazine do
      equipment_type { "weapon_attachment" }
      item_type { "magazine" }
      weapon_class { nil }
      sub_type { "Magazine" }
      storage { 40 }
    end

    trait :hidden do
      hidden { true }
    end
  end
end
