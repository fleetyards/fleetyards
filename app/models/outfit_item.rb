# frozen_string_literal: true

class OutfitItem < ApplicationRecord
  # The worn slots the dressing room draws. Clothing has no holos to draw.
  ARMOR_SLOTS = %w[undersuit torso arms legs helmet backpack].freeze

  # Where a weapon is carried: two primaries stowed on the back, a sidearm in
  # the thigh holster. Not equipment slots, so numbered clear of them.
  WEAPON_SLOTS = {"primary" => 100, "secondary" => 101, "sidearm" => 102}.freeze

  # What each weapon slot takes, by the weapon's sub type.
  WEAPON_SUB_TYPES = {
    "primary" => %w[Medium Large],
    "secondary" => %w[Medium Large],
    "sidearm" => %w[Small]
  }.freeze

  SLOTS = (ARMOR_SLOTS + WEAPON_SLOTS.keys).freeze

  belongs_to :outfit, inverse_of: :items
  belongs_to :equipment

  enum :slot, Equipment.slots.slice(*ARMOR_SLOTS).merge(WEAPON_SLOTS), validate: true

  validate :equipment_fits_slot

  def weapon_slot?
    WEAPON_SLOTS.key?(slot)
  end

  private def equipment_fits_slot
    return if equipment.nil? || slot.nil?
    return if weapon_slot? ? fits_weapon_slot? : equipment.slot == slot

    errors.add(:equipment, :wrong_slot)
  end

  private def fits_weapon_slot?
    equipment.equipment_type == "weapon" && WEAPON_SUB_TYPES.fetch(slot).include?(equipment.sub_type)
  end
end
