# frozen_string_literal: true

# One model a mission ship will accept. A ship spot names either one exact model,
# a list of models it will take, or the criteria a model has to meet — this is the
# middle case, one row per allowed model.
# == Schema Information
#
# Table name: mission_ship_models
#
#  id              :uuid             not null, primary key
#  position        :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mission_ship_id :uuid             not null
#  model_id        :uuid             not null
#
# Indexes
#
#  index_mission_ship_models_on_mission_ship_id    (mission_ship_id)
#  index_mission_ship_models_on_model_id           (model_id)
#  index_mission_ship_models_on_ship_and_model     (mission_ship_id,model_id) UNIQUE
#  index_mission_ship_models_on_ship_and_position  (mission_ship_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (mission_ship_id => mission_ships.id) ON DELETE => cascade
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
class MissionShipModel < ApplicationRecord
  belongs_to :mission_ship, touch: true
  belongs_to :model

  validates :model_id, uniqueness: {scope: :mission_ship_id}

  default_scope -> { order(position: :asc) }

  def mission
    mission_ship&.mission
  end
end
