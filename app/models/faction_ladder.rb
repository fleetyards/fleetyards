# frozen_string_literal: true

# One reputation ladder a faction offers, as one build of the game states it.
class FactionLadder < ApplicationRecord
  belongs_to :build, class_name: "FactionBuild", inverse_of: :ladders,
    foreign_key: :faction_build_id

  validates :key, presence: true
  validates :name, presence: true
end
