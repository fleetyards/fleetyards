# frozen_string_literal: true

# == Schema Information
#
# Table name: cargo_holds
#
#  id                        :uuid             not null, primary key
#  capacity_scu              :decimal(15, 2)   not null
#  dimension_x               :decimal(15, 2)   not null
#  dimension_y               :decimal(15, 2)   not null
#  dimension_z               :decimal(15, 2)   not null
#  max_container_dimension_x :decimal(15, 2)
#  max_container_dimension_y :decimal(15, 2)
#  max_container_dimension_z :decimal(15, 2)
#  max_container_size_scu    :integer          not null
#  min_container_dimension_x :decimal(15, 2)
#  min_container_dimension_y :decimal(15, 2)
#  min_container_dimension_z :decimal(15, 2)
#  min_container_size_scu    :integer
#  name                      :string
#  offset_x                  :decimal(15, 2)
#  offset_y                  :decimal(15, 2)
#  offset_z                  :decimal(15, 2)
#  position                  :integer
#  rotation                  :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  model_id                  :uuid             not null
#
# Indexes
#
#  index_cargo_holds_on_capacity_scu                         (capacity_scu)
#  index_cargo_holds_on_model_id                             (model_id)
#  index_cargo_holds_on_model_id_and_max_container_size_scu  (model_id,max_container_size_scu)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id)
#
class CargoHold < ApplicationRecord
  belongs_to :model, touch: true
  has_many :cargo_hold_container_capacities, dependent: :destroy

  validates :dimension_x, :dimension_y, :dimension_z, :capacity_scu,
    :max_container_size_scu, presence: true
  validates :dimension_x, :dimension_y, :dimension_z, :capacity_scu,
    numericality: {greater_than: 0}
  validates :max_container_size_scu,
    numericality: {greater_than: 0, only_integer: true}

  scope :ordered, -> { order(:position, :id) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[model_id name position]
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
