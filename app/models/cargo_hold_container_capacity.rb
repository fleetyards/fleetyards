# frozen_string_literal: true

class CargoHoldContainerCapacity < ApplicationRecord
  belongs_to :cargo_hold

  validates :container_size_scu, :max_quantity, presence: true
  validates :container_size_scu, uniqueness: {scope: :cargo_hold_id}
  validates :max_quantity, numericality: {greater_than_or_equal_to: 0, only_integer: true}

  # Standard container sizes
  CONTAINER_SIZES = [1, 2, 4, 8, 16, 24, 32].freeze

  validates :container_size_scu, inclusion: {in: CONTAINER_SIZES}

  scope :for_size, ->(size) { where(container_size_scu: size) }
  scope :with_capacity, -> { where("max_quantity > 0") }
end
