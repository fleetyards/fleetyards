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
