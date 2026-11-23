# frozen_string_literal: true

# A set of worn equipment a user put together in the dressing room and kept
# under a name: at most one item per worn, weapon or gear slot, which of the
# weapons is in hand, what is kept in the storage of the worn pieces, and
# optionally the user's own character wearing it.
class Outfit < ApplicationRecord
  MAX_PER_USER = 50

  belongs_to :user
  belongs_to :character_face, optional: true

  has_many :items, -> { order(:slot) },
    class_name: "OutfitItem", inverse_of: :outfit, dependent: :delete_all, autosave: true

  has_many :stored_items, -> { order(:holder, :created_at) },
    class_name: "OutfitStoredItem", inverse_of: :outfit, dependent: :delete_all, autosave: true

  validates :name, presence: true, length: {maximum: 100}, uniqueness: {scope: :user_id}
  validates :held_weapon, inclusion: {in: OutfitItem::WEAPON_SLOTS.keys}, allow_nil: true
  validates :body, inclusion: {in: ItemViews::RIGGED_BODIES}
  validate :outfit_limit, on: :create
  validate :held_weapon_worn
  validate :character_face_fits, if: :character_face_id

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

  # Replaces what the worn pieces hold with `[{holder:, equipment_id:, quantity:}]`.
  def stored_item_list=(list)
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

  private def character_face_fits
    if character_face.nil? || character_face.user_id != user_id
      errors.add(:character_face, :not_owned)
    elsif character_face.body != body
      errors.add(:character_face, :other_body)
    end
  end

  private def outfit_limit
    return if user.blank?
    return if user.outfits.count < MAX_PER_USER

    errors.add(:base, :outfit_limit_reached, count: MAX_PER_USER)
  end
end
