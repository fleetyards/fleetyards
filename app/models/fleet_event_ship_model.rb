# frozen_string_literal: true

# One model a fleet event ship will accept. A ship spot names either one exact
# model, a list of models it will take, or the criteria a model has to meet —
# this is the middle case, one row per allowed model.
class FleetEventShipModel < ApplicationRecord
  belongs_to :fleet_event_ship, touch: true
  belongs_to :model

  validates :model_id, uniqueness: {scope: :fleet_event_ship_id}

  default_scope -> { order(position: :asc) }

  def fleet_event
    fleet_event_ship&.fleet_event
  end
end
