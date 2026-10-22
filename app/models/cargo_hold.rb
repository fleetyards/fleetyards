# frozen_string_literal: true

class CargoHold < ApplicationRecord
  paginates_per 24

  belongs_to :parent, polymorphic: true, touch: true
  has_many :cargo_hold_container_capacities, dependent: :destroy

  validates :dimension_x, :dimension_y, :dimension_z, :capacity_scu,
    :max_container_size_scu, presence: true
  validates :dimension_x, :dimension_y, :dimension_z, :capacity_scu,
    numericality: {greater_than: 0}
  validates :max_container_size_scu,
    numericality: {greater_than: 0, only_integer: true}
  validates :max_loadable_container_size_scu,
    inclusion: {in: CargoHoldContainerCapacity::CONTAINER_SIZES}, allow_nil: true
  # Only when it is set: a load that shrinks the grid under a curated limit has
  # to go through, and the limit then simply stops applying.
  validates :max_loadable_container_size_scu,
    numericality: {less_than: :max_container_size_scu}, allow_nil: true,
    if: :will_save_change_to_max_loadable_container_size_scu?

  after_update :calculate_container_capacities!, if: :saved_change_to_max_loadable_container_size_scu?

  scope :ordered, -> { order(:position, :id) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[parent_type parent_id name position]
  end

  # The grid takes the crates that fit its floor, but some can only be reached
  # through a door or a lift too small for the largest of them -- the Clipper's
  # grid fits an 8 SCU crate its door does not. The game files describe no door,
  # so that limit is set by hand and survives every load.
  def effective_max_container_size_scu
    [max_container_size_scu, max_loadable_container_size_scu].compact.min
  end

  # Calculate and populate container capacities for all container sizes
  def calculate_container_capacities!
    ScData::CargoFinder::CARGO_CONTAINER_DIMENSIONS.each do |container_def|
      calculate_capacity_for_size(container_def[:size], container_def[:dimensions])
    end
  end

  private def calculate_capacity_for_size(size, container_dims)
    orientations = [
      {name: "normal", x: container_dims[:x], y: container_dims[:y], z: container_dims[:z]},
      {name: "rotated", x: container_dims[:y], y: container_dims[:x], z: container_dims[:z]}
    ]

    max_count = 0
    best_orientation = nil

    orientations.each do |orientation|
      next if size > effective_max_container_size_scu
      next unless orientation[:x] <= dimension_x &&
        orientation[:y] <= dimension_y &&
        orientation[:z] <= dimension_z

      count_x = (dimension_x / orientation[:x]).floor
      count_y = (dimension_y / orientation[:y]).floor
      count_z = (dimension_z / orientation[:z]).floor
      total = count_x * count_y * count_z

      if total > max_count
        max_count = total
        best_orientation = orientation[:name]
      end
    end

    cargo_hold_container_capacities.find_or_initialize_by(container_size_scu: size).update!(
      max_quantity: max_count,
      best_orientation:
    )
  end
end
