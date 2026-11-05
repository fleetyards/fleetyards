# frozen_string_literal: true

FactoryBot.define do
  factory :faction do
    sequence(:sc_key) { |n| "factionreputation_lawful_faction#{n}" }
    sequence(:sc_ref) { |n| Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "faction-#{n}") }
    sequence(:name) { |n| "Faction #{n}" }
    version { ScData::Source.version }

    transient do
      description { "Private security." }
      lawful { true }
      alignment { "lawful" }
      with_build { true }
    end

    after(:create) do |faction, evaluator|
      next unless evaluator.with_build

      faction.builds.create!(
        environment: ScData::Source.environment,
        version: faction.version,
        name: faction.read_attribute(:name),
        description: evaluator.description,
        lawful: evaluator.lawful,
        alignment: evaluator.alignment
      )

      faction.association(:build).reset
      faction.association(:last_build).reset
    end
  end

  factory :faction_ladder do
    build factory: :faction_build
    key { "reputationscope_hauling" }
    name { "Hauling" }
    ceiling { 367_601 }
    ranks { [{name: "Trainee", min_reputation: 0}, {name: "Rookie", min_reputation: 50}] }
    sequence(:position) { |n| n }
  end

  factory :faction_build do
    faction factory: :faction, with_build: false
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    sequence(:name) { |n| "Faction #{n}" }
  end
end
