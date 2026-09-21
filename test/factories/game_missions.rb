# frozen_string_literal: true

FactoryBot.define do
  factory :game_mission do
    sequence(:name) { |n| "Yellow Level Contract: Ambush An Amateur #{n}" }
    sequence(:sc_key) { |n| "foxwellenforcement_ambush_veryeasy_#{n}" }
    sequence(:sc_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "game-mission-#{n}") }
    description { "Somebody needs teaching a lesson." }
    kind { "career" }
    generator_key { "foxwellenforcement_ambush" }
    sequence(:debug_name) { |n| "Foxwell_ShipAmbush_VeryEasy_#{n}" }
    org_key { "factionreputation_lawful_foxwellenforcement" }
    org_name { "Foxwell Enforcement" }
    # Foxwell Enforcement is a UEE-side security org, and the export says so.
    org_lawful { true }
    alignment { "lawful" }
    sequence(:org_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "org-#{n}") }
    min_standing { "Neutral" }
    max_standing { "Elite Contractor" }
    released { true }
    difficulty_profile { "general" }
    difficulty_mechanical_skill { 3 }
    difficulty_mental_load { 3 }
    difficulty_risk_of_loss { 2 }
    difficulty_game_knowledge { 2 }
    reward_kinds { ["reputation"] }
    version { ScData::Source.version }

    transient { with_build { true } }

    # Mirrors what a load leaves behind: the row and the build describing it.
    after(:create) do |mission, evaluator|
      next unless evaluator.with_build
      next if mission.version.blank?

      mission.builds.create!(
        environment: ScData::Source.environment,
        version: mission.version,
        **mission.attributes.symbolize_keys.slice(*GameMissionBuild::FACTS)
      )

      mission.association(:build).reset
      mission.association(:last_build).reset
    end

    # For tests that manage builds themselves and would otherwise collide with
    # the one above on the unique index.
    trait :without_build do
      with_build { false }
    end

    # In the files but in front of nobody: 349 of the 2536 carry one of the two
    # flags that mean this.
    trait :unreleased do
      released { false }
    end

    # A handler that names no faction, inside a generator that names more than
    # one: the org is left blank rather than guessed.
    trait :unattributed do
      org_key { nil }
      org_name { nil }
      org_ref { nil }
      org_lawful { nil }
      alignment { nil }
    end
  end
end
