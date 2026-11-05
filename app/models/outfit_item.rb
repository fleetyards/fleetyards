# frozen_string_literal: true

class OutfitItem < ApplicationRecord
  # The worn slots the dressing room draws. Clothing has no holos to draw.
  ARMOR_SLOTS = %w[undersuit torso arms legs helmet backpack].freeze

  # Where a weapon is carried: a primary and a second, smaller one stowed on
  # the back, a sidearm in the thigh holster. Not equipment slots, so numbered
  # clear of them.
  WEAPON_SLOTS = {"primary" => 100, "secondary" => 101, "sidearm" => 102}.freeze

  # What each weapon slot takes, by the weapon's sub type.
  WEAPON_SUB_TYPES = {
    "primary" => %w[Medium Large],
    "secondary" => %w[Medium],
    "sidearm" => %w[Small]
  }.freeze

  # Gear carried on a worn piece, one to a port. Stored as integers, so a number
  # here can never be reused for another slot.
  GEAR_SLOTS = {
    "grenade_1" => 110, "grenade_2" => 111, "grenade_3" => 112, "grenade_4" => 113,
    "magazine_1" => 120, "magazine_2" => 121, "magazine_3" => 122, "magazine_4" => 123,
    "magazine_5" => 124, "magazine_6" => 125, "magazine_7" => 126, "magazine_8" => 127,
    "gadget_1" => 130,
    "medpen_1" => 140, "medpen_2" => 141,
    "oxypen_1" => 150, "oxypen_2" => 151,
    "utility_1" => 160, "utility_2" => 161
  }.freeze

  # The game's port behind each kind of gear slot, numbered as the slot is.
  GEAR_PORTS = {
    "grenade" => "grenade_attach",
    "magazine" => "magazine_attach",
    "gadget" => "gadget_attach",
    "medpen" => "medPen_attach",
    "oxypen" => "oxyPen_attach",
    "utility" => "utility_attach"
  }.freeze

  # What each kind of gear slot takes. The pen ports accept any consumable, so
  # which pen goes where is told apart here by its sub type.
  GEAR_ITEMS = {
    "grenade" => {equipment_types: %w[weapon tool], sub_types: %w[Grenade]},
    "magazine" => {equipment_types: %w[weapon_attachment], sub_types: %w[Magazine]},
    "gadget" => {equipment_types: %w[tool mining_gadget], sub_types: %w[Gadget]},
    "medpen" => {equipment_types: %w[medical], sub_types: %w[MedPack Medical]},
    "oxypen" => {equipment_types: %w[medical], sub_types: %w[OxygenCap]},
    "utility" => {equipment_types: %w[weapon tool], sub_types: %w[Knife Gadget]}
  }.freeze

  SLOTS = (ARMOR_SLOTS + WEAPON_SLOTS.keys + GEAR_SLOTS.keys).freeze

  belongs_to :outfit, inverse_of: :items
  belongs_to :equipment

  enum :slot, Equipment.slots.slice(*ARMOR_SLOTS).merge(WEAPON_SLOTS, GEAR_SLOTS), validate: true

  validate :equipment_fits_slot

  def weapon_slot?
    WEAPON_SLOTS.key?(slot)
  end

  def gear_slot?
    GEAR_SLOTS.key?(slot)
  end

  def gear_port
    kind, number = slot.split("_")

    "#{GEAR_PORTS.fetch(kind)}_#{number}"
  end

  def offered_ports
    Array.wrap(equipment&.fit&.dig("ports")).pluck("name")
  end

  private def equipment_fits_slot
    return if equipment.nil? || slot.nil?
    return if fits_slot?

    errors.add(:equipment, :wrong_slot)
  end

  private def fits_slot?
    return fits_weapon_slot? if weapon_slot?
    return fits_gear_slot? if gear_slot?

    equipment.slot == slot
  end

  private def fits_gear_slot?
    rule = GEAR_ITEMS.fetch(slot.split("_").first)

    rule[:equipment_types].include?(equipment.equipment_type) && rule[:sub_types].include?(equipment.sub_type)
  end

  private def fits_weapon_slot?
    equipment.equipment_type == "weapon" && WEAPON_SUB_TYPES.fetch(slot).include?(equipment.sub_type)
  end
end
