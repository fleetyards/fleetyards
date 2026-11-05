# frozen_string_literal: true

# A set of worn equipment a user put together in the dressing room and kept
# under a name: at most one item per worn, weapon or gear slot, which of the
# weapons is in hand, and what is kept in the storage of the worn pieces.
class Outfit < ApplicationRecord
  MAX_PER_USER = 50

  belongs_to :user

  has_many :items, -> { order(:slot) },
    class_name: "OutfitItem", inverse_of: :outfit, dependent: :delete_all, autosave: true

  has_many :stored_items,
    class_name: "OutfitStoredItem", inverse_of: :outfit, dependent: :delete_all, autosave: true

  validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
  validates :held_weapon, inclusion: {in: OutfitItem::WEAPON_SLOTS.keys}, allow_nil: true
  validates :body, inclusion: {in: ItemViews::RIGGED_BODIES}
  validate :outfit_limit, on: :create
  validate :held_weapon_worn
  # Only when the contents change: a patch that takes a port away must not stop
  # an old outfit from being renamed.
  validate :gear_on_offered_ports, if: -> { @contents_assigned }
  validate :stored_items_fit, if: -> { @contents_assigned }

  # Replaces what the outfit wears with `[{slot:, equipment_id:}]`. A slot left
  # out is emptied; a slot already worn keeps its row, so changing an item never
  # trips the one-item-per-slot index halfway through a save.
  def item_list=(list)
    @contents_assigned = true
    wanted = list.to_h { |item| [item[:slot].to_s, item[:equipment_id]] }

    items.each { |item| item.mark_for_destruction unless wanted.key?(item.slot) }

    wanted.each do |slot, equipment_id|
      item = items.find { |existing| existing.slot == slot } || items.build(slot:)
      item.equipment_id = equipment_id
    end
  end

  # Replaces what the worn pieces hold with `[{holder:, equipment_id:, quantity:}]`.
  def stored_item_list=(list)
    @contents_assigned = true
    wanted = list.group_by { |item| [item[:holder].to_s, item[:equipment_id].to_s] }
      .transform_values { |entries| entries.sum { |entry| entry[:quantity].to_i } }

    stored_items.each do |item|
      item.mark_for_destruction unless wanted.key?([item.holder, item.equipment_id])
    end

    wanted.each do |(holder, equipment_id), quantity|
      item = stored_items.find { |existing| existing.holder == holder && existing.equipment_id == equipment_id } ||
        stored_items.build(holder:, equipment_id:)
      item.quantity = quantity
    end
  end

  # The weapon in hand is one the outfit carries.
  private def held_weapon_worn
    return if held_weapon.nil?
    return if items.any? { |item| item.slot == held_weapon && !item.marked_for_destruction? }

    errors.add(:held_weapon, :not_carried)
  end

  private def worn_items
    items.reject(&:marked_for_destruction?)
  end

  private def gear_on_offered_ports
    worn = worn_items
    offered = worn.flat_map(&:offered_ports)

    errors.add(:items, :no_port) if worn.any? { |item| item.gear_slot? && offered.exclude?(item.gear_port) }
  end

  private def stored_items_fit
    pieces = worn_items.index_by(&:slot)

    stored_items.reject(&:marked_for_destruction?).select(&:equipment).group_by(&:holder).each do |holder, stored|
      inventory = pieces[holder]&.equipment&.inventory

      errors.add(:stored_items, :no_storage) and next if inventory.blank?

      errors.add(:stored_items, :over_capacity) if stored.sum(&:micro_scu) > inventory["capacity"]
      errors.add(:stored_items, :too_large) if stored.any? { |item| !fits_inside?(item.equipment, inventory) }
    end
  end

  # An item may be turned to fit, so sides are compared longest to longest.
  private def fits_inside?(equipment, inventory)
    sides = equipment.volume_dimensions&.values
    return true if sides.blank?

    sides.sort.zip(inventory["dimensions"].values.sort).all? { |side, interior| side <= interior }
  end

  private def outfit_limit
    return if user.blank?
    return if user.outfits.count < MAX_PER_USER

    errors.add(:base, :outfit_limit_reached, count: MAX_PER_USER)
  end
end
