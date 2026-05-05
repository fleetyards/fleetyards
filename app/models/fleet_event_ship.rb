# frozen_string_literal: true

class FleetEventShip < ApplicationRecord
  belongs_to :fleet_event_team, touch: true
  belongs_to :model, optional: true
  belongs_to :source_ship, class_name: "MissionShip", optional: true
  has_many :fleet_event_slots, as: :slottable, dependent: :destroy

  delegate :fleet_event, to: :fleet_event_team

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
    title.presence || model&.name || I18n.t("labels.fleet_event_ship.placeholder", default: "Unspecified Ship")
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
