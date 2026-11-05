# frozen_string_literal: true

# Something kept in the storage of a worn piece, as many of it as the outfit
# carries there.
class OutfitStoredItem < ApplicationRecord
  HOLDER_SLOTS = %w[torso legs backpack undersuit].freeze
  MAX_QUANTITY = 999

  belongs_to :outfit, inverse_of: :stored_items
  belongs_to :equipment

  enum :holder, Equipment.slots.slice(*HOLDER_SLOTS), validate: true

  validates :quantity, numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_QUANTITY}
  validate :equipment_measured

  def micro_scu
    equipment.volume.to_d * 1_000_000 * quantity
  end

  private def equipment_measured
    return if equipment.nil? || equipment.volume.present?

    errors.add(:equipment, :unmeasured)
  end
end
