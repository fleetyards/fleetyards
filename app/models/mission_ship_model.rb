# frozen_string_literal: true

# One model a mission ship will accept. A ship spot names either one exact model,
# a list of models it will take, or the criteria a model has to meet — this is the
# middle case, one row per allowed model.
class MissionShipModel < ApplicationRecord
  belongs_to :mission_ship, touch: true
  belongs_to :model

  validates :model_id, uniqueness: {scope: :mission_ship_id}

  default_scope -> { order(position: :asc) }

  def mission
    mission_ship&.mission
  end
end
