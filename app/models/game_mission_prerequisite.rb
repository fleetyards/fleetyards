# frozen_string_literal: true

# One thing a player has to have, or not have, before a mission is offered, as
# one build of the game states it.
class GameMissionPrerequisite < ApplicationRecord
  belongs_to :build, class_name: "GameMissionBuild", inverse_of: :prerequisites,
    foreign_key: :game_mission_build_id

  KINDS = %w[crime_stat reputation completed_missions excluded_missions].freeze

  validates :kind, presence: true, inclusion: {in: KINDS}
end
