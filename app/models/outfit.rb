# frozen_string_literal: true

# A set of worn equipment a user put together in the dressing room and kept
# under a name: at most one item per worn or weapon slot, and which of the
# weapons is in hand.
class Outfit < ApplicationRecord
  MAX_PER_USER = 50

  belongs_to :user

  has_many :items, -> { order(:slot) },
    class_name: "OutfitItem", inverse_of: :outfit, dependent: :delete_all, autosave: true

  validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
  validates :held_weapon, inclusion: {in: OutfitItem::WEAPON_SLOTS.keys}, allow_nil: true
  validate :outfit_limit, on: :create
  validate :held_weapon_worn

  # Replaces what the outfit wears with `[{slot:, equipment_id:}]`. A slot left
  # out is emptied; a slot already worn keeps its row, so changing an item never
  # trips the one-item-per-slot index halfway through a save.
  def item_list=(list)
    wanted = list.to_h { |item| [item[:slot].to_s, item[:equipment_id]] }

    items.each { |item| item.mark_for_destruction unless wanted.key?(item.slot) }

    wanted.each do |slot, equipment_id|
      item = items.find { |existing| existing.slot == slot } || items.build(slot:)
      item.equipment_id = equipment_id
    end
  end

  # The weapon in hand is one the outfit carries.
  private def held_weapon_worn
    return if held_weapon.nil?
    return if items.any? { |item| item.slot == held_weapon && !item.marked_for_destruction? }

    errors.add(:held_weapon, :not_carried)
  end

  private def outfit_limit
    return if user.blank?
    return if user.outfits.count < MAX_PER_USER

    errors.add(:base, :outfit_limit_reached, count: MAX_PER_USER)
  end
end
