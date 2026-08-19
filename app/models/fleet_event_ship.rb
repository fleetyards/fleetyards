# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_event_ships
#
#  id                  :uuid             not null, primary key
#  classification      :string
#  description         :text
#  focus               :string
#  max_size            :string
#  min_cargo           :decimal(, )
#  min_crew            :integer
#  min_size            :string
#  position            :integer          default(0), not null
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_event_team_id :uuid             not null
#  model_id            :uuid
#  source_ship_id      :uuid
#
# Indexes
#
#  index_fleet_event_ships_on_fleet_event_team_id               (fleet_event_team_id)
#  index_fleet_event_ships_on_fleet_event_team_id_and_position  (fleet_event_team_id,position)
#  index_fleet_event_ships_on_model_id                          (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_team_id => fleet_event_teams.id)
#  fk_rails_...  (model_id => models.id)
#  fk_rails_...  (source_ship_id => mission_ships.id) ON DELETE => nullify
#
class FleetEventShip < ApplicationRecord
  belongs_to :fleet_event_team, touch: true
  belongs_to :model, optional: true
  belongs_to :source_ship, class_name: "MissionShip", optional: true
  has_many :fleet_event_slots, as: :slottable, dependent: :destroy
  has_many :fleet_event_ship_models, dependent: :destroy
  has_many :allowed_models, through: :fleet_event_ship_models, source: :model

  delegate :fleet_event, to: :fleet_event_team

  default_scope -> { order(position: :asc) }

  FILTER_ATTRIBUTES = %i[classification focus min_size max_size min_crew min_cargo].freeze

  validate :model_or_filter_required
  validate :model_must_be_in_game
  validate :allowed_models_must_be_in_game

  def strict?
    model_id.present?
  end

  # A hand-picked set of models rather than criteria: the spot takes any one of
  # them, so a signup matches if its ship is in the list.
  def listed?
    fleet_event_ship_models.any?
  end

  def filtered?
    FILTER_ATTRIBUTES.any? { |attr| self[attr].present? }
  end

  def display_title
    title.presence || model&.name || I18n.t("labels.fleet_event_ship.placeholder", default: "Unspecified Ship")
  end

  private def model_or_filter_required
    return if strict? || listed? || filtered?

    errors.add(:base, :model_or_filter_required)
  end

  private def model_must_be_in_game
    return if model.blank?
    return if model.in_game?

    errors.add(:model_id, :must_be_in_game)
  end

  # The same bar the single model has to clear: a spot cannot ask for a ship that
  # is not in the game yet, however it names it.
  #
  # Read through the join rows rather than through allowed_models: a has_many
  # :through on an unsaved parent queries the database and so comes back empty,
  # which let a new spot list a concept ship unchecked.
  private def allowed_models_must_be_in_game
    return if fleet_event_ship_models.map(&:model).compact.all?(&:in_game?)

    errors.add(:allowed_model_ids, :must_be_in_game)
  end
end
