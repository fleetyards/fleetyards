# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicle_loadout_hardpoints
#
#  id                 :uuid             not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  component_id       :uuid
#  model_hardpoint_id :uuid             not null
#  vehicle_loadout_id :uuid             not null
#
# Indexes
#
#  idx_vehicle_loadout_hardpoints_unique                   (vehicle_loadout_id,model_hardpoint_id) UNIQUE
#  index_vehicle_loadout_hardpoints_on_vehicle_loadout_id  (vehicle_loadout_id)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id)
#  fk_rails_...  (model_hardpoint_id => model_hardpoints.id)
#  fk_rails_...  (vehicle_loadout_id => vehicle_loadouts.id)
#
class VehicleLoadoutHardpoint < ApplicationRecord
  belongs_to :vehicle_loadout
  belongs_to :model_hardpoint
  belongs_to :component, optional: true

  validates :model_hardpoint_id, uniqueness: {scope: :vehicle_loadout_id}
end
