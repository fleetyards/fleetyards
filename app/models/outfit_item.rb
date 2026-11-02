# frozen_string_literal: true

class OutfitItem < ApplicationRecord
  # The worn slots the dressing room draws. Clothing has no holos to draw.
  SLOTS = %w[undersuit torso arms legs helmet backpack].freeze

  belongs_to :outfit, inverse_of: :items
  belongs_to :equipment

  enum :slot, Equipment.slots.slice(*SLOTS), validate: true

  validate :equipment_fits_slot

  private def equipment_fits_slot
    return if equipment.nil? || slot.nil?
    return if equipment.slot == slot

    errors.add(:equipment, :wrong_slot)
  end
end
