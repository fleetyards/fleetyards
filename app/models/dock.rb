# frozen_string_literal: true

class Dock < ApplicationRecord
  belongs_to :station

  enum dock_type: %i[vehiclepad garage landingpad dockingport hangar]
  ransacker :dock_type, formatter: proc { |v| Dock.dock_types[v] } do |parent|
    parent.table[:dock_type]
  end
  enum ship_size: %i[extra_small small medium large extra_large capital]
  ransacker :ship_size, formatter: proc { |v| Dock.ship_sizes[v] } do |parent|
    parent.table[:ship_size]
  end

  validates :dock_type, :station_id, :ship_size, presence: true

  def self.size_filters
    Dock.ship_sizes.map do |(item, _index)|
      Filter.new(
        category: 'ship_size',
        name: Dock.human_enum_name(:ship_size, item),
        value: item
      )
    end
  end

  def self.type_filters
    Dock.dock_types.map do |(item, _index)|
      Filter.new(
        category: 'dock_type',
        name: Dock.human_enum_name(:dock_type, item),
        value: item
      )
    end
  end

  def dock_type_label
    Dock.human_enum_name(:dock_type, dock_type)
  end

  def ship_size_label
    Dock.human_enum_name(:ship_size, ship_size)
  end
end
