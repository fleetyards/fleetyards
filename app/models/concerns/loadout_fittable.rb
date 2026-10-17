# frozen_string_literal: true

# Something a loadout slot can hold. The item column is polymorphic, so no
# foreign key removes the fittings with the record; they are destroyed instead,
# so each loadout it was fitted in is touched, along with what sat inside it.
module LoadoutFittable
  extend ActiveSupport::Concern

  included do
    has_many :vehicle_loadout_items, as: :item, dependent: nil
    before_destroy :unfit_everywhere
  end

  private def unfit_everywhere
    vehicle_loadout_items.find_each do |item|
      VehicleLoadoutItem.where(vehicle_loadout_id: item.vehicle_loadout_id)
        .where("slot_path LIKE ?", "#{VehicleLoadoutItem.sanitize_sql_like(item.slot_path)}/%")
        .destroy_all
      item.destroy!
    end
  end
end
