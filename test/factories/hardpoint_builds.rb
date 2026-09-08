# == Schema Information
#
# Table name: hardpoint_builds
#
#  id            :uuid             not null, primary key
#  category      :integer
#  environment   :string           not null
#  flags         :string
#  group         :integer
#  group_key     :string
#  max_size      :integer
#  min_size      :integer
#  port_tags     :string
#  required_tags :string
#  types         :string
#  version       :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  component_id  :uuid
#  hardpoint_id  :uuid             not null
#
# Indexes
#
#  index_hardpoint_builds_on_component_id             (component_id)
#  index_hardpoint_builds_on_environment_and_version  (environment,version)
#  index_hardpoint_builds_on_hardpoint_and_build      (hardpoint_id,environment,version) UNIQUE
#  index_hardpoint_builds_on_hardpoint_id             (hardpoint_id)
#
# Foreign Keys
#
#  fk_rails_...  (hardpoint_id => hardpoints.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :hardpoint_build do
    # `game_files` explicitly rather than the hardpoint factory's random source:
    # only that half carries build rows, and a matrix slot with one would be the
    # very thing the design forbids.
    association :hardpoint, factory: [:hardpoint, :without_build], source: :game_files
    environment { ScData::Source.environment }
    version { ScData::Source.version }
    min_size { 2 }
    max_size { 2 }
  end
end
