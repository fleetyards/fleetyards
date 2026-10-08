# frozen_string_literal: true

FactoryBot.define do
  factory :commodity_build do
    commodity
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    sequence(:name) { |n| "#{Faker::Commerce.material} #{n}" }
    commodity_type { "metal" }
    description { Faker::Lorem.sentence }
  end
end
