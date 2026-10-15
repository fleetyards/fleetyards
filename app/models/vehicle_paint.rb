# frozen_string_literal: true

# A paint the ship owns. Which one it wears is the loadout's to say once the
# loadout editor takes paints; until then a vehicle records ownership only.
class VehiclePaint < ApplicationRecord
  belongs_to :vehicle, touch: true
  belongs_to :model_paint

  validates :model_paint_id, uniqueness: {scope: :vehicle_id}
  validate :paint_of_the_vehicles_model, if: :will_save_change_to_model_paint_id?

  private def paint_of_the_vehicles_model
    return if model_paint.blank? || vehicle.blank?
    return if model_paint.model_id == vehicle.model_id

    errors.add(:model_paint, :invalid)
  end
end
