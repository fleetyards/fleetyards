# frozen_string_literal: true

# == Schema Information
#
# Table name: mission_ships
#
#  id              :uuid             not null, primary key
#  classification  :string
#  description     :text
#  focus           :string
#  max_size        :string
#  min_cargo       :decimal(, )
#  min_crew        :integer
#  min_size        :string
#  position        :integer          default(0), not null
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mission_team_id :uuid             not null
#  model_id        :uuid
#
# Indexes
#
#  index_mission_ships_on_mission_team_id               (mission_team_id)
#  index_mission_ships_on_mission_team_id_and_position  (mission_team_id,position)
#  index_mission_ships_on_model_id                      (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (mission_team_id => mission_teams.id)
#  fk_rails_...  (model_id => models.id)
#
class MissionShip < ApplicationRecord
  belongs_to :mission_team, touch: true
  belongs_to :model, optional: true
  has_many :mission_slots, as: :slottable, dependent: :destroy

  delegate :mission, to: :mission_team

  default_scope -> { order(position: :asc) }

  FILTER_ATTRIBUTES = %i[classification focus min_size max_size min_crew min_cargo].freeze

  validate :model_or_filter_required
  validate :model_must_be_in_game

  def strict?
    model_id.present?
  end

  def filtered?
    FILTER_ATTRIBUTES.any? { |attr| self[attr].present? }
  end

  def display_title
    title.presence || model&.name || I18n.t("labels.mission_ship.placeholder")
  end

  private def model_or_filter_required
    return if strict? || filtered?

    errors.add(:base, :model_or_filter_required)
  end

  private def model_must_be_in_game
    return if model.blank?
    return if model.in_game?

    errors.add(:model_id, :must_be_in_game)
  end
end
