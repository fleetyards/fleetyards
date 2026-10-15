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

  # The module each slot comes with from the factory, by slot: the game files
  # name it as the slot's stock component. Every vehicle of the model can fit
  # these without owning them.
  def self.stock_modules(model)
    stock_keys = model.hardpoints.where(category: :module, source: :game_files)
      .includes(:component)
      .each_with_object({}) do |hp, keys|
        key = hp.component&.sc_key&.downcase
        keys[hp.sc_name] = key if key.present?
      end
    return {} if stock_keys.empty?

    where(model:, slot: stock_keys.keys).includes(:model_module)
      .each_with_object({}) do |module_hardpoint, stock|
        next unless module_hardpoint.model_module.sc_key&.downcase == stock_keys[module_hardpoint.slot]

        stock[module_hardpoint.slot] = module_hardpoint.model_module_id
      end
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
