FactoryBot.define do
  factory :hardpoint_build do
    # `game_files` explicitly rather than the hardpoint factory's random source:
    # only that half carries build rows, and a matrix slot with one would be the
    # very thing the design forbids.
    association :hardpoint, factory: :hardpoint, source: :game_files
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    min_size { 2 }
    max_size { 2 }
  end
end
