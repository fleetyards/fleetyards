# frozen_string_literal: true

module Maintenance
  class BackfillModuleHardpointSlotsTask < MaintenanceTasks::Task
    def collection
      ModuleHardpoint.where(slot: nil)
    end

    def count
      collection.count
    end

    def process(module_hardpoint)
      return if module_hardpoint.model_module.blank?

      slot = ModuleHardpoint.derive_slot(module_hardpoint.model, module_hardpoint.model_module)

      module_hardpoint.update!(slot: slot) if slot.present?
    end
  end
end
