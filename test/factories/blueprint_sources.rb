# frozen_string_literal: true

FactoryBot.define do
  factory :blueprint_source do
    build factory: :blueprint_build
    kind { "contract" }
    sequence(:pool_sc_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "pool-#{n}") }
    pool_key { "bp_missionreward_example" }
    pool_group { "blueprintmissionpools" }
    weight { 1 }
    org_name { "Foxwell Enforcement" }
    # Foxwell Enforcement is a UEE-side security org, and the export says so.
    alignment { "lawful" }
    sequence(:org_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "org-#{n}") }
    source_key { "foxwellenforcement_ambush" }
    mission_name { "Yellow Level Contract: Ambush An Amateur" }
    min_standing { "Neutral" }
    max_standing { "Elite Contractor" }
    sequence(:position) { |n| n }

    # XenoThreat hands its pools out by scenario progress rather than by
    # contract, so there is no mission and no standing band -- a points
    # threshold instead.
    trait :scenario do
      kind { "scenario" }
      pool_group { "xenothreat2rewards" }
      source_key { "rox_scenarioprogress" }
      mission_name { nil }
      min_standing { nil }
      max_standing { nil }
      min_points { 18_000 }
    end

    # A generator naming more than one faction: the org is left blank rather
    # than guessed.
    trait :unattributed do
      org_name { nil }
      org_ref { nil }
      # No org, so no side of the law -- the loader leaves it blank rather than
      # guessing which of the named factions the pool came from.
      alignment { nil }
    end
  end
end
