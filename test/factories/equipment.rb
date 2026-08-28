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
#  g_force_tolerance      :decimal(15, 2)
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  item_type              :string
#  name                   :string
#  radiation_protection   :decimal(15, 2)
#  radiation_scrub_rate   :decimal(15, 2)
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  sc_key                 :string
#  sc_ref                 :string
#  size                   :string
#  slot                   :integer
#  slug                   :string
#  storage                :decimal(15, 2)
#  sub_type               :string
#  temperature_rating     :string
#  version                :string
#  volume                 :decimal(15, 6)
#  volume_dimensions      :jsonb
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
#  index_equipment_on_slot             (slot)
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
    version { ScData::Source.version }

    transient { with_build { true } }

    # A build describing the item, mirroring what the backfill did for the rows
    # already in the table. Keyed on the row's own version, so
    # `create(:equipment, version: <older>)` is retired here too.
    after(:create) do |equipment, evaluator|
      next unless evaluator.with_build
      next if equipment.version.blank?

      equipment.builds.create!(
        environment: ScData::Source.environment,
        version: equipment.version,
        **equipment.attributes.symbolize_keys.slice(*EquipmentBuild::FACTS)
      )

      # Validating the row consulted a fact reader, which cached the build as it
      # was then -- absent. Dropped so the record behaves like a freshly loaded one.
      equipment.association(:build).reset
      equipment.association(:last_build).reset
    end

    # For tests that manage builds themselves and would otherwise collide with
    # the one above.
    trait :without_build do
      with_build { false }
    end

    trait :with_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

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

    trait :armor do
      equipment_type { "armor" }
      item_type { "heavy_utility" }
      weapon_class { nil }
      sub_type { "Heavy" }
      slot { :torso }
      damage_reduction { 25 }
      temperature_rating { "-225 / 75 °C" }
      radiation_protection { 33_600 }
      radiation_scrub_rate { 147.42 }
      backpack_compatibility { :all }
    end

    trait :hidden do
      hidden { true }
    end
  end
end
