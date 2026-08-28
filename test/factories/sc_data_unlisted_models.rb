# frozen_string_literal: true

FactoryBot.define do
  factory :sc_data_unlisted_model do
    sequence(:identifier) { |n| "drak_newhull_#{n}" }
    name { "Drake Newhull" }
    manufacturer_code { "DRAK" }
    comparison { "unrelated" }

    first_seen_version { ScData::Source.version }
    first_seen_environment { ScData::Source.environment }
    last_seen_version { ScData::Source.version }
    last_seen_environment { ScData::Source.environment }

    trait :decided do
      decision { "ignored" }
      decided_at { Time.current }
    end
  end
end
