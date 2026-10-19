# frozen_string_literal: true

# A crafted part: the recipe it was made from, and the grade of material in
# each of the recipe's slots, keyed by the slot's position -- a re-parse
# rewrites every slot row under a new id, but the position stays.
#
# Shared by what holds such a part (a ledger entry) and what asks for one (a
# contract line). The two differ in one thing: a part someone holds was made at
# some grade in every slot, while a request may leave a slot open.
module CraftedPart
  extend ActiveSupport::Concern

  # What a player can craft and hold: parts and gear. A crafted commodity is
  # just more of that commodity, which its grade already describes.
  CRAFTED_ITEM_TYPES = %w[Component Equipment].freeze

  # The slots whose material moves a stat, which are the ones a crafted part
  # says the grade of. A slot without modifiers takes any grade and changes
  # nothing.
  def self.graded_slot_positions(blueprint)
    blueprint.cost_slots
      .where(id: ::BlueprintCostModifier.select(:blueprint_cost_slot_id))
      .pluck(:position)
      .sort
  end

  included do
    belongs_to :crafted_blueprint, class_name: "Blueprint", optional: true
  end

  def crafted?
    crafted_blueprint_id.present?
  end

  # Keyed by the slot's position as a string, whichever way the caller wrote
  # it: JSON object keys are strings anyway, and a jsonb column compares and
  # groups them as written. An absent value stays NULL rather than becoming
  # `{}`, which the stock would group apart from every entry without grades.
  def crafted_qualities=(value)
    value = value.to_h.transform_keys(&:to_s) if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)

    super(value.presence)
  end

  # Checked when the crafting is written, or the part it is for changes -- not
  # on every later save: a recipe the game retires or reshapes must not make
  # what was recorded against it uneditable.
  private def crafting_written?
    (crafted_blueprint_id? || crafted_qualities.present?) &&
      (new_record? || will_save_change_to_crafted_blueprint_id? || will_save_change_to_crafted_qualities? ||
        will_save_change_to_item_id? || will_save_change_to_item_type?)
  end

  # Whether every graded slot must carry a grade.
  private def crafted_grades_required?
    true
  end

  private def crafted_from_a_recipe_for_the_item
    if crafted_blueprint.blank?
      errors.add(:crafted_blueprint_id, :blank)
      return
    end

    part = item if item_type.in?(CRAFTED_ITEM_TYPES) && item_id.present?

    if part.blank?
      errors.add(:crafted_blueprint_id, :invalid, message: "only a component or equipment item can be crafted")
      return
    end

    unless ::Blueprint.making(part).exists?(id: crafted_blueprint_id)
      errors.add(:crafted_blueprint_id, :invalid, message: "does not make #{part.name}")
      return
    end

    crafted_qualities_fit_the_recipe
  end

  private def crafted_qualities_fit_the_recipe
    # A recipe with no graded slot is recorded with no grades, which is stored
    # as NULL.
    qualities = crafted_qualities || {}

    unless qualities.is_a?(Hash)
      errors.add(:crafted_qualities, :invalid, message: "must name a grade per recipe slot")
      return
    end

    expected = CraftedPart.graded_slot_positions(crafted_blueprint).map(&:to_s)
    named = qualities.keys.map(&:to_s)

    fits = crafted_grades_required? ? named.sort == expected.sort : (named - expected).empty?

    unless fits
      errors.add(:crafted_qualities, :invalid, message: "must name a grade for slots #{expected.join(", ")}")
      return
    end

    return if qualities.values.all? { |grade| grade.is_a?(Integer) && grade.between?(0, 1000) }

    errors.add(:crafted_qualities, :invalid, message: "grades must be whole numbers from 0 to 1000")
  end
end
