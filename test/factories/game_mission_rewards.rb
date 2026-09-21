# frozen_string_literal: true

FactoryBot.define do
  factory :game_mission_reward do
    build factory: :game_mission_build
    kind { "reputation" }
    amount { 100 }
    org_key { "factionreputation_lawful_foxwellenforcement" }
    org_name { "Foxwell Enforcement" }
    sequence(:position) { |n| n }

    # One of the eight contracts in 4.10.1 that state a figure at all.
    trait :currency do
      kind { "currency" }
      amount { 40_000 }
      currency { "UEC" }
      org_key { nil }
      org_name { nil }
    end

    trait :item do
      kind { "item" }
      amount { 1 }
      entity_class { Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "entity-class") }
      org_key { nil }
      org_name { nil }
    end

    trait :badge do
      kind { "badge" }
      amount { nil }
      badge { "WelcomeToPyro_Firesale" }
      org_key { nil }
      org_name { nil }
    end

    # 16 of the 58 amounts the export declares are negative: work for one side
    # costs you standing with the other.
    trait :penalty do
      amount { -1_000 }
    end
  end
end
