FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Everus Harbor #{n}" }
    sequence(:sc_key) { |n| "RR_HUR_LEO_#{n}" }
    sc_refs { [Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "location-#{sc_key}")] }
    description { "A rest stop in Hurston's orbit." }
    kind { "station" }
    game_type { "Manmade" }
    shown_on_starmap { true }
    quantum_travel_destination { true }
    version { ScData::Source.version }

    transient { with_build { true } }

    # Mirrors what a load leaves behind: the row and the build describing it.
    after(:create) do |location, evaluator|
      next unless evaluator.with_build
      next if location.version.blank?

      location.builds.create!(
        environment: ScData::Source.environment,
        version: location.version,
        **location.attributes.symbolize_keys.slice(*LocationBuild::FACTS)
      )

      location.association(:build).reset
      location.association(:last_build).reset
    end

    trait :without_build do
      with_build { false }
    end
  end
end
