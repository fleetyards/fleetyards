# frozen_string_literal: true

# One thing a mission pays, as one build of the game states it.
#
# A mission can carry a lot of these -- the busiest awards reputation with three
# orgs and a weighted set of eleven items -- because the export declares one
# result per outcome and per recipient.
# == Schema Information
#
# Table name: game_mission_rewards
#
#  id                    :uuid             not null, primary key
#  amount                :integer
#  badge                 :string
#  currency              :string
#  entity_class          :string
#  entity_name           :string
#  kind                  :string           not null
#  max                   :integer
#  org_key               :string
#  org_name              :string
#  position              :integer          not null
#  weight                :decimal(8, 3)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  game_mission_build_id :uuid             not null
#
# Indexes
#
#  index_game_mission_rewards_on_build               (game_mission_build_id)
#  index_game_mission_rewards_on_build_and_position  (game_mission_build_id,position) UNIQUE
#  index_game_mission_rewards_on_kind                (kind)
#
# Foreign Keys
#
#  fk_rails_...  (game_mission_build_id => game_mission_builds.id) ON DELETE => cascade
#
class GameMissionReward < ApplicationRecord
  belongs_to :build, class_name: "GameMissionBuild", inverse_of: :rewards,
    foreign_key: :game_mission_build_id

  # Reputation and items are most of it; a badge is a cosmetic the game tracks;
  # currency is the eight contracts that state a figure.
  #
  # `ContractResult_CalculatedReward` is deliberately not a kind. It is what the
  # other 2352 award and it states nothing at all -- carrying it would put a
  # reward on a page that could say only "there is one".
  KINDS = %w[reputation item badge currency].freeze

  validates :kind, presence: true, inclusion: {in: KINDS}

  scope :of_kind, ->(kind) { where(kind:) }

  # The game works the figure out when it generates the mission, so the export
  # states that the contract pays and not how much. 2352 of the 2536 are in
  # this position against 8 that state an amount -- which is why the amount
  # being absent has to be said rather than left as a blank.
  #
  # Unambiguous without a column of its own: every one of the 8 carries an
  # amount, including the contract whose amount is zero.
  def calculated?
    kind == "currency" && amount.nil?
  end

  # A reputation loss is a reward the same way a gain is: 16 of the 58 amounts
  # the export declares are negative, and a contract that costs you standing
  # with the other side is stating a real consequence.
  def penalty?
    kind == "reputation" && amount.to_i.negative?
  end
end
