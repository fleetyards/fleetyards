# frozen_string_literal: true

# == Schema Information
#
# Table name: commodities
#
#  id             :uuid             not null, primary key
#  commodity_type :string
#  description    :text
#  name           :string           not null
#  sc_key         :string
#  sc_ref         :string
#  slug           :string           not null
#  uex_code       :string
#  version        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  uex_id         :integer
#
# Indexes
#
#  index_commodities_on_commodity_type  (commodity_type)
#  index_commodities_on_sc_key          (sc_key) UNIQUE
#  index_commodities_on_slug            (slug) UNIQUE
#  index_commodities_on_uex_code        (uex_code)
#
FactoryBot.define do
  factory :commodity do
    sequence(:name) { |n| "#{Faker::Commerce.material} #{n}" }
    sequence(:sc_key) { |n| "items_commodities_test_#{n}" }
    commodity_type { "metal" }
    description { Faker::Lorem.sentence }
    version { Rails.configuration.sc_data[:version] }

    transient { with_build { true } }

    # A build describing the commodity, mirroring what the backfill did for the
    # rows already in the table. Keyed on the row's own version, so
    # `create(:commodity, version: <older>)` is retired here too, and skipped
    # entirely for a row with no version -- the UEX importer creates those, and
    # the export never named them.
    after(:create) do |commodity, evaluator|
      next unless evaluator.with_build
      next if commodity.version.blank?

      commodity.builds.create!(
        environment: ScData::Source.environment,
        version: commodity.version,
        **commodity.attributes.symbolize_keys.slice(*CommodityBuild::FACTS)
      )

      # Validating the row consulted a fact reader, which cached the build as it
      # was then -- absent. Dropped so the record behaves like a freshly loaded one.
      commodity.association(:build).reset
      commodity.association(:last_build).reset
    end

    # For tests that manage builds themselves and would otherwise collide with
    # the one above on the unique index.
    trait :without_build do
      with_build { false }
    end

    trait :with_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test.png"), "image/png") }
    end

    # What the export actually ships for a commodity, and what the loader
    # attaches: the game draws these icons from vectors.
    trait :with_vector_store_image do
      store_image { Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/vector.svg"), "image/svg+xml") }
    end

    trait :mineral do
      commodity_type { "mineral" }
    end

    trait :with_uex_mapping do
      sequence(:uex_id) { |n| n }
      sequence(:uex_code) { |n| "UEXC#{n}" }
    end
  end
end
