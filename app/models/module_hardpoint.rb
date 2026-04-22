# frozen_string_literal: true

# == Schema Information
#
# Table name: module_hardpoints
#
#  id              :uuid             not null, primary key
#  slot            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_id        :uuid
#  model_module_id :uuid
#
# Indexes
#
#  index_module_hardpoints_on_model_id_and_slot  (model_id,slot)
#
class ModuleHardpoint < ApplicationRecord
  belongs_to :model, touch: true, counter_cache: true
  belongs_to :model_module

  POSITION_KEYWORDS = %w[front rear bow stern].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["model_id", "model_module_id", "slot", "created_at", "updated_at"]
  end

  def self.derive_slot(model, model_module)
    module_slots = model.hardpoints.where(category: :module, source: :game_files)
    return nil if module_slots.empty?

    mod_key = (model_module.sc_key || "").downcase

    slot = module_slots.find do |hp|
      hp_name = hp.sc_name || ""

      hp.component&.sc_key&.downcase == mod_key ||
        POSITION_KEYWORDS.any? { |kw| hp_name.include?(kw) && mod_key.include?(kw) }
    end

    slot ||= module_slots.first if module_slots.count == 1

    slot&.sc_name
  end
end
