# frozen_string_literal: true

class Dock < ApplicationRecord
  belongs_to :station

  enum dock_type: %i[vehiclepad garage landingpad dockingport hangar]
  enum ship_size: %i[small medium medium_large large extra_large capital]

  validates :dock_type, :station_id, :ship_size, presence: true

  def dock_type_label
    Dock.human_enum_name(:dock_type, dock_type)
  end

  def ship_size_label
    Dock.human_enum_name(:ship_size, ship_size)
  end
end
