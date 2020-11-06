# frozen_string_literal: true

# == Schema Information
#
# Table name: docks
#
#  id            :uuid             not null, primary key
#  beam          :decimal(15, 2)
#  dock_type     :integer
#  group         :string
#  height        :decimal(15, 2)
#  length        :decimal(15, 2)
#  max_ship_size :integer
#  min_ship_size :integer
#  name          :string
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid
#  station_id    :uuid
#
# Indexes
#
#  index_docks_on_station_id  (station_id)
#
class Dock < ApplicationRecord
  belongs_to :station, optional: true
  belongs_to :model, optional: true

  enum dock_type: { vehiclepad: 0, garage: 1, landingpad: 2, dockingport: 3, hangar: 4 }
  ransacker :dock_type, formatter: proc { |v| Dock.dock_types[v] } do |parent|
    parent.table[:dock_type]
  end
  enum ship_size: { extra_small: 0, small: 1, medium: 2, large: 3, extra_large: 4, capital: 5 }
  ransacker :ship_size, formatter: proc { |v| Dock.ship_sizes[v] } do |parent|
    parent.table[:ship_size]
  end

  validates :dock_type, :ship_size, presence: true

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
