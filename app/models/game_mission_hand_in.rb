# frozen_string_literal: true

# One thing a mission asks to be brought to it, as one build of the game states
# it.
class GameMissionHandIn < ApplicationRecord
  belongs_to :build, class_name: "GameMissionBuild", inverse_of: :hand_ins,
    foreign_key: :game_mission_build_id

  belongs_to :catalogue_item, polymorphic: true, optional: true

  KINDS = %w[item resource].freeze

  validates :kind, presence: true, inclusion: {in: KINDS}
  validates :ref, presence: true
  validates :amount, presence: true
end
