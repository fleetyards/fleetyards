FactoryBot.define do
  factory :hardpoint do
    source { Hardpoint.sources.keys.sample }
    sc_name { Faker::Alphanumeric.alphanumeric(number: 10) }
    association :parent, factory: :model

    transient { with_build { true } }

    # A build describing the slot, mirroring what the backfill task did for the
    # rows already in the table. Without one a game-files slot is in no build at
    # all, and `in_build` -- so the endpoint -- does not offer it. The same
    # reason the component factory carries one.
    #
    # Only the game-files half: the matrix comes from no build and `in_build`
    # passes it without a row.
    after(:create) do |hardpoint, evaluator|
      next unless evaluator.with_build
      next unless hardpoint.game_files?

      hardpoint.builds.create!(
        environment: ScData::Source.environment,
        version: ScData::Source.version,
        **HardpointBuild.facts_from(hardpoint)
      )

      # The slot was validated before this row existed, so `facts` may have
      # cached the absence. Dropped so the record behaves like a loaded one.
      hardpoint.association(:build).reset
    end

    # For tests that manage builds themselves and would otherwise collide with
    # the one above.
    trait :without_build do
      with_build { false }
    end
  end
end
