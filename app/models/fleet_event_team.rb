# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_teams
#
#  id             :uuid             not null, primary key
#  description    :text
#  position       :integer          default(0), not null
#  title          :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  fleet_event_id :uuid             not null
#  source_team_id :uuid
#
# Indexes
#
#  index_fleet_event_teams_on_fleet_event_id               (fleet_event_id)
#  index_fleet_event_teams_on_fleet_event_id_and_position  (fleet_event_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_id => fleet_events.id)
#  fk_rails_...  (source_team_id => mission_teams.id) ON DELETE => nullify
#
class FleetEventTeam < ApplicationRecord
  belongs_to :fleet_event, touch: true
  belongs_to :source_team, class_name: "MissionTeam", optional: true
  has_many :fleet_event_ships, dependent: :destroy
  has_many :fleet_event_slots, as: :slottable, dependent: :destroy

  validates :title, presence: true

  default_scope -> { order(position: :asc) }
end
