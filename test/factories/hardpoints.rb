# == Schema Information
#
# Table name: hardpoints
#
#  id            :uuid             not null, primary key
#  category      :integer
#  details       :string
#  flags         :string
#  group         :integer
#  group_key     :string
#  matrix_key    :string
#  max_size      :integer
#  min_size      :integer
#  parent_type   :string           not null
#  port_tags     :string
#  required_tags :string
#  sc_name       :string
#  source        :integer
#  types         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  component_id  :uuid
#  parent_id     :uuid             not null
#
# Indexes
#
#  index_hardpoints_on_component_id        (component_id)
#  index_hardpoints_on_parent              (parent_type,parent_id)
#  index_hardpoints_on_parent_and_sc_name  (parent_type,parent_id,sc_name) UNIQUE WHERE (source = 1)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id)
#
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
