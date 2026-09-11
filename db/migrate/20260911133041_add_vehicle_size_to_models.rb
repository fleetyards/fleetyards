# frozen_string_literal: true

class AddVehicleSizeToModels < ActiveRecord::Migration[8.1]
  # A ladder of t-shirt sizes for ground vehicles, anchored on reference
  # vehicles: ATLS, then the hover bikes, then PTV/UTV, Cyclone, Ursa, and
  # Nova/Ballista at the top. "Holds an Ursa" is the answer a berth wants to
  # give; "10 x 7 x 6" is not.
  #
  # Separate from `size`, which only says *that* something is a vehicle. Curated
  # rather than derived: the Cyclone base variants are recorded 8.75m wide,
  # wider than an Ursa, which inverts the order by volume.
  def change
    add_column :models, :vehicle_size, :string
  end
end
