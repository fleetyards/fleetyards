# frozen_string_literal: true

FactoryBot.define do
  factory :blueprint_build do
    blueprint
    environment { ScData::Source.environment }
    version { ScData::Source.version }

    sequence(:name) { |n| "Crafted Item #{n}" }
    craft_time { 120 }
    slot_count { 3 }
  end
end
