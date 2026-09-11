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
#  parent_type   :string           not null
#  ship_size     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  model_id      :uuid
#  parent_id     :uuid             not null
#
# Indexes
#
#  index_docks_on_parent_type_and_parent_id  (parent_type,parent_id)
#
class Dock < ApplicationRecord
  # A hull or a module, and nothing else. `parent_type` is a plain string
  # column, so without this the admin API would take any class name at all and
  # a dock could end up hanging off a User -- a new way to grow the orphans
  # #4864 had to delete.
  PARENT_TYPES = %w[Model ModelModule].freeze

  belongs_to :parent, polymorphic: true, touch: true

  validates :parent_type, inclusion: {in: PARENT_TYPES}

  # The admin form used to preselect landingpad/medium for anyone who did not
  # touch the dropdowns, so a garage could be saved as a landing pad and offered
  # to ships. The form now starts empty, which only works if a berth with no
  # type cannot be stored. All 28 ship docks carry both today.
  validates :dock_type, :ship_size, presence: true

  enum :dock_type,
    {vehiclepad: 0, garage: 1, landingpad: 2, dockingport: 3, hangar: 4}
  ransacker :dock_type, formatter: proc { |v| Dock.dock_types[v] } do |parent|
    parent.table[:dock_type]
  end

  enum :ship_size,
    {
      extra_extra_small: -1, extra_small: 0, small: 1, medium: 2, large: 3, extra_large: 4,
      capital: 5
    }
  ransacker :ship_size, formatter: proc { |v| Dock.ship_sizes[v] } do |parent|
    parent.table[:ship_size]
  end

  # The module this berth arrives with, and nil when it is built into the hull.
  # A module berth is conditional -- whether the ship is carrying that module is
  # the player's choice -- so it is named rather than presented as a fixture.
  def model_module_name
    parent.name if parent_type == "ModelModule"
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      "beam", "created_at", "dock_type", "group", "height", "id", "id_value", "length",
      "max_ship_size", "min_ship_size", "name", "parent_id", "parent_type", "ship_size",
      "updated_at"
    ]
  end

  SHIP_SIZE_METRICS = {
    extra_extra_small: {
      x: 12,
      y: 16,
      z: 6
    },
    extra_small: {
      x: 24,
      y: 32,
      z: 12

    },
    small: {
      x: 48,
      y: 48,
      z: 16
    },
    medium: {
      x: 56,
      y: 88,
      z: 18
    },
    large: {
      x: 72,
      y: 128,
      z: 36
    },
    extra_large: {
      x: 160,
      y: 272,
      z: 64
    },
    capital: {
      x: 160,
      y: 272,
      z: 64
    }
  }.freeze

  validates :dock_type, :ship_size, presence: true

  def self.size_filters
    Dock.ship_sizes.map do |(item, _index)|
      Filter.new(
        category: "ship_size",
        label: Dock.human_enum_name(:ship_size, item),
        value: item
      )
    end
  end

  def self.type_filters
    Dock.dock_types.map do |(item, _index)|
      Filter.new(
        category: "dock_type",
        label: Dock.human_enum_name(:dock_type, item),
        value: item
      )
    end
  end

  # What a dock takes and how much room it wants. Both settled by the hangar
  # filter, which is the rule that survived: it is the one that tells a garage
  # from a landing pad. A docking port is in neither list -- it is a connection,
  # not a place a hull is set down.
  SHIP_DOCK_TYPES = %w[landingpad hangar].freeze
  VEHICLE_DOCK_TYPES = %w[vehiclepad garage].freeze

  SHIP_CLEARANCE = {length: 2.0, beam: 2.0, height: 1.0}.freeze
  VEHICLE_CLEARANCE = {length: 1.0, beam: 1.0, height: 0.5}.freeze

  # The largest of a kind is the only one worth asking: docks of a kind nest by
  # size, so nothing that misses the biggest fits a smaller one.
  def self.largest_ship_dock(docks)
    docks.select { |dock| dock.for_ships? && dock.measured? }.max_by(&:length)
  end

  def self.largest_vehicle_dock(docks)
    docks.select { |dock| dock.for_vehicles? && dock.measured? }.max_by(&:length)
  end

  def for_ships?
    SHIP_DOCK_TYPES.include?(dock_type)
  end

  def for_vehicles?
    VEHICLE_DOCK_TYPES.include?(dock_type)
  end

  # A docking port is neither: it is a connection, not a berth, so nothing is
  # ever measured against it.
  def berth?
    for_ships? || for_vehicles?
  end

  def clearance
    for_vehicles? ? VEHICLE_CLEARANCE : SHIP_CLEARANCE
  end

  # A bay takes vehicles, a pad takes ships, and asking the wrong one is not a
  # near miss but a different question.
  #
  # `size` decides, never `ground`. The latter means "cannot reach space", which
  # is why every hover bike — Nox, Dragonfly, X1, Pulse — is `ground: false`
  # while still berthing as a vehicle: eleven of the forty-four.
  #
  # Deliberately the strict reading for now. A vehicle can in fact be got into a
  # hangar, by ramp or lift or in the last resort a tractor beam, but which dock
  # offers which is not recorded — see the follow-up. Saying nothing is better
  # than claiming a fit nobody can achieve.
  def fits?(model)
    return false unless measured?
    return false unless accepts?(model)

    model.length.to_f <= length - clearance[:length] &&
      model.beam.to_f <= beam - clearance[:beam] &&
      model.height.to_f <= height - clearance[:height]
  end

  private def accepts?(model)
    return false unless for_ships? || for_vehicles?

    (model.size == ::Model::VEHICLE_SIZE) == for_vehicles?
  end

  def measured?
    length.present? && beam.present? && height.present?
  end

  def dock_type_label
    Dock.human_enum_name(:dock_type, dock_type)
  end

  def ship_size_label
    Dock.human_enum_name(:ship_size, ship_size)
  end
end
