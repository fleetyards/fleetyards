# frozen_string_literal: true

# A ship that could fill a slot, configured like a hangar ship: paint, modules
# and upgrade kits.
class HangarPlanCandidate < ApplicationRecord
  belongs_to :slot, class_name: "HangarPlanSlot", foreign_key: :hangar_plan_slot_id,
    inverse_of: :candidates, touch: true
  belongs_to :model
  belongs_to :model_paint, optional: true

  has_many :acquisitions, -> { order(:created_at) },
    class_name: "HangarPlanAcquisition", inverse_of: :candidate, dependent: :destroy

  validates :model_id, uniqueness: {scope: :hangar_plan_slot_id}
  validate :configuration_matches_model

  before_create :append_position

  delegate :hangar_plan, to: :slot

  def model_modules
    model_module_ids.empty? ? ModelModule.none : ModelModule.where(id: model_module_ids)
  end

  def model_upgrades
    model_upgrade_ids.empty? ? ModelUpgrade.none : ModelUpgrade.where(id: model_upgrade_ids)
  end

  # What paint, modules and upgrade kits add to buying the ship, in USD. Nil
  # parts are listed by the summary as unknown rather than counted as free.
  def extras
    [model_paint, *model_modules.to_a, *model_upgrades.to_a].compact
  end

  private def configuration_matches_model
    return if model.blank?

    errors.add(:model_paint_id, :invalid) if model_paint.present? && model_paint.model_id != model_id
    errors.add(:model_module_ids, :invalid) if model_module_ids.uniq.size != model.modules.where(id: model_module_ids).count
    errors.add(:model_upgrade_ids, :invalid) if model_upgrade_ids.uniq.size != model.upgrades.where(id: model_upgrade_ids).count
  end

  private def append_position
    self.position = (slot.candidates.maximum(:position) || -1) + 1 if position.zero?
  end
end
