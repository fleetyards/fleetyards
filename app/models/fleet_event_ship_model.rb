# frozen_string_literal: true

# One model a fleet event ship will accept. A ship spot names either one exact
# model, a list of models it will take, or the criteria a model has to meet —
# this is the middle case, one row per allowed model.
# == Schema Information
#
# Table name: fleet_event_ship_models
#
#  id                  :uuid             not null, primary key
#  position            :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_event_ship_id :uuid             not null
#  model_id            :uuid             not null
#
# Indexes
#
#  index_fleet_event_ship_models_on_model_id           (model_id)
#  index_fleet_event_ship_models_on_ship               (fleet_event_ship_id)
#  index_fleet_event_ship_models_on_ship_and_model     (fleet_event_ship_id,model_id) UNIQUE
#  index_fleet_event_ship_models_on_ship_and_position  (fleet_event_ship_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_event_ship_id => fleet_event_ships.id) ON DELETE => cascade
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
class FleetEventShipModel < ApplicationRecord
  belongs_to :fleet_event_ship, touch: true
  belongs_to :model

  validates :model_id, uniqueness: {scope: :fleet_event_ship_id}

  default_scope -> { order(position: :asc) }

  def fleet_event
    fleet_event_ship&.fleet_event
  end
end
