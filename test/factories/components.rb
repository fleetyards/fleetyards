# == Schema Information
#
# Table name: components
#
#  id                    :uuid             not null, primary key
#  ammunition            :string
#  category              :string
#  component_class       :string
#  component_sub_type    :string
#  component_type        :string
#  description           :text
#  durability            :string
#  grade                 :string
#  heat_connection       :string
#  hidden                :boolean          default(FALSE)
#  inventory_consumption :string
#  item_class            :integer
#  item_type             :string
#  name                  :string(255)
#  power_connection      :string
#  sc_key                :string
#  sc_ref                :string
#  size                  :string(255)
#  slug                  :string
#  tracking_signal       :integer
#  type_data             :string
#  version               :string
#  created_at            :datetime
#  updated_at            :datetime
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#  index_components_on_sc_key           (sc_key) UNIQUE
#  index_components_on_version          (version)
#
FactoryBot.define do
  factory :component do
    name { Faker::Name.name }
    component_class { "RSIModular" }

    # Needed now that the catalogue filter is an inner join to the build: without
    # a version there is no build, and a component without a build is not in the
    # catalogue at all. The same reason the equipment factory carries one.
    version { ScData::Source.version }

    transient { with_build { true } }

    # A build describing the component, mirroring what the backfill did for the
    # rows already in the table. Keyed on the row's own version, so
    # `create(:component, version: <older>)` is retired here too, and skipped
    # entirely for a row with no version -- the export never named it.
    after(:create) do |component, evaluator|
      next unless evaluator.with_build
      next if component.version.blank?

      component.builds.create!(
        environment: ScData::Source.environment,
        version: component.version,
        **component.attributes.symbolize_keys.slice(*ComponentBuild::FACTS)
      )

      # Validating the row consulted a fact reader, which cached the build as it
      # was then -- absent. Dropped so the record behaves like a freshly loaded one.
      component.association(:build).reset
      component.association(:last_build).reset
    end

    # For tests that manage builds themselves and would otherwise collide with
    # the one above.
    trait :without_build do
      with_build { false }
    end

    trait :with_manufacturer do
      manufacturer
    end

    trait :with_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    trait :hidden do
      hidden { true }
    end

    trait :weapon do
      item_type { "WeaponGun" }
      category { "weapon" }
      component_type { "gun" }
      size { "S3" }
    end

    trait :shield do
      item_type { "Shield" }
      category { "defense" }
      component_type { "shield_generator" }
      size { "S2" }
    end
  end
end
