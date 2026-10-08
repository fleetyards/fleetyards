# frozen_string_literal: true

# What one build of the game says about a mission, following the shape
# `blueprint_builds`, `commodity_builds`, `equipment_builds` and
# `component_builds` established.
class GameMissionBuild < ApplicationRecord
  belongs_to :game_mission

  # What this build says the mission pays. Destroyed with the build, which is
  # what makes `prune_builds` and `retire_absent_builds` carry the rewards too.
  has_many :rewards,
    -> { order(:position) },
    class_name: "GameMissionReward", inverse_of: :build,
    foreign_key: :game_mission_build_id, dependent: :destroy

  # A recipe is handed out through a reward pool rather than as a contract
  # result, so it is not a `GameMissionReward` row -- but it is something the
  # mission pays, and `reward_kinds` carries it so a reader can filter for it
  # without knowing which side of the export it came from.
  BLUEPRINT_REWARD_KIND = "blueprint"

  # Everything a mission can be said to pay, which is the four the export
  # states as contract results plus the recipes it hands out.
  REWARD_KINDS = (::GameMissionReward::KINDS + [BLUEPRINT_REWARD_KIND]).freeze

  FACTS = %i[
    name description kind generator_key debug_name
    org_ref org_key org_name org_lawful alignment
    min_standing max_standing released
    difficulty_profile difficulty_mechanical_skill difficulty_mental_load
    difficulty_risk_of_loss difficulty_game_knowledge
    reward_kinds blueprint_pool_refs
    location_kind needs_landing
  ].freeze

  # Everything: a mission has no associations served off a fact column, so
  # nothing has to be held back the way `blueprint_builds` holds the craftable.
  READ_THROUGH = FACTS

  # The facts a browsable catalogue filters and sorts by.
  #
  # The two arrays are deliberately out. `all_facts_join` wraps every filterable
  # fact in a COALESCE, and an array compared through one cannot use the GIN
  # index that exists for it -- those two are asked through a scope instead.
  # `debug_name` and `generator_key` are here for admin rather than for the
  # public catalogue: a developer's note is not a mission name, but it is how a
  # row is found again in the export when its title is a run-time template or
  # absent. Filterable rather than merely ransackable, so they resolve through
  # the joined build like every other fact -- ransack drops a condition it
  # cannot place without saying a word, which is a filter that silently matches
  # everything.
  FILTERABLE = %i[
    name kind org_key org_name alignment min_standing max_standing released
    difficulty_profile difficulty_mechanical_skill difficulty_mental_load
    difficulty_risk_of_loss difficulty_game_knowledge
    debug_name generator_key
    location_kind needs_landing
  ].freeze

  validates :environment, presence: true
  validates :version, presence: true
  validates :game_mission_id, uniqueness: {scope: [:environment, :version]}

  scope :for_source, ->(source = ::ScData::Source.current) {
    where(environment: source.environment)
  }

  scope :current, ->(source = ::ScData::Source.current) {
    where(environment: source.environment, version: source.version)
  }

  def self.retained_versions(environment, keep: ::ScData::Source.builds_retained(environment))
    where(environment:)
      .group(:version)
      .minimum(:created_at)
      .sort_by { |_version, first_seen| first_seen }
      .last(keep)
      .map(&:first)
  end
end
