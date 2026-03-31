# frozen_string_literal: true

# == Schema Information
#
# Table name: cargo_hold_container_capacities
#
#  id                 :uuid             not null, primary key
#  best_orientation   :string
#  container_size_scu :integer          not null
#  max_quantity       :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  cargo_hold_id      :uuid             not null
#
# Indexes
#
#  index_cargo_hold_capacities_on_hold_and_size                 (cargo_hold_id,container_size_scu) UNIQUE
#  index_cargo_hold_container_capacities_on_container_size_scu  (container_size_scu)
#  index_cargo_hold_container_capacities_on_max_quantity        (max_quantity)
#
# Foreign Keys
#
#  fk_rails_...  (cargo_hold_id => cargo_holds.id)
#
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
