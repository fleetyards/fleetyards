# frozen_string_literal: true

# == Schema Information
#
# Table name: mission_teams
#
#  id          :uuid             not null, primary key
#  description :text
#  position    :integer          default(0), not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  mission_id  :uuid             not null
#
# Indexes
#
#  index_mission_teams_on_mission_id               (mission_id)
#  index_mission_teams_on_mission_id_and_position  (mission_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (mission_id => missions.id)
#
class MissionTeam < ApplicationRecord
  belongs_to :mission, touch: true
  has_many :mission_ships, dependent: :destroy
  has_many :mission_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true

  default_scope -> { order(position: :asc) }
end
