# frozen_string_literal: true

# Links made before slots were derived on import never got one, and a module
# with no slot cannot be fitted in a loadout. Ships whose game files have no
# module hardpoints yet keep a nil slot.
class BackfillModuleHardpointSlots < ActiveRecord::Migration[8.1]
  def up
    ModuleHardpoint.where(slot: nil).includes(:model, :model_module).find_each do |module_hardpoint|
      slot = ModuleHardpoint.derive_slot(module_hardpoint.model, module_hardpoint.model_module)
      next if slot.blank?

      module_hardpoint.update!(slot:)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
