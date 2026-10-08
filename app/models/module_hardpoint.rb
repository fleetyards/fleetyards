# frozen_string_literal: true

class ModuleHardpoint < ApplicationRecord
  belongs_to :model, touch: true, counter_cache: true
  # Linking, unlinking or editing a slot changes what the module embeds, and
  # its cached fragments are keyed on the module.
  belongs_to :model_module, touch: true

  POSITION_KEYWORDS = %w[front rear bow stern left right].freeze

  def self.ransackable_attributes(auth_object = nil)
    ["model_id", "model_module_id", "slot", "created_at", "updated_at"]
  end

  def self.derive_slot(model, model_module)
    module_slots = model.hardpoints.where(category: :module, source: :game_files)
    return nil if module_slots.empty?

    mod_key = (model_module.sc_key || "").downcase
    mod_name = (model_module.name || "").downcase

    slot = module_slots.find do |hp|
      hp_name = hp.sc_name || ""

      hp.component&.sc_key&.downcase == mod_key ||
        POSITION_KEYWORDS.any? do |kw|
          hp_name.include?(kw) && (mod_key.include?(kw) || mod_name.include?(kw))
        end
    end

    slot ||= module_slots.first if module_slots.count == 1

    slot&.sc_name
  end
end
