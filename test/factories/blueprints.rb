# frozen_string_literal: true

FactoryBot.define do
  factory :blueprint do
    sequence(:name) { |n| "Crafted Item #{n}" }
    sequence(:sc_key) { |n| "bp_craft_test_#{n}" }
    sequence(:sc_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "blueprint-#{n}") }
    category_ref { Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "category") }
    craft_time { 120 }
    slot_count { 3 }
    version { ScData::Source.version }

    transient { with_build { true } }

    # Mirrors what a load leaves behind: the row and the build describing it.
    after(:create) do |blueprint, evaluator|
      next unless evaluator.with_build
      next if blueprint.version.blank?

      blueprint.builds.create!(
        environment: ScData::Source.environment,
        version: blueprint.version,
        **blueprint.attributes.symbolize_keys.slice(*BlueprintBuild::FACTS)
      )

      blueprint.association(:build).reset
      blueprint.association(:last_build).reset
    end

    # For tests that manage builds themselves and would otherwise collide with
    # the one above on the unique index.
    trait :without_build do
      with_build { false }
    end

    trait :for_component do
      craftable factory: :component
    end

    trait :for_equipment do
      craftable factory: :equipment
    end

    # A recipe whose output is in no catalogue -- 28 of the 1607 in 4.10.1.
    trait :without_craftable do
      craftable { nil }
    end
  end
end
