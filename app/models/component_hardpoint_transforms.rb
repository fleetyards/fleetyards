# frozen_string_literal: true

# Where on a module's hull holo each of its item ports sits, and how its doors
# open, as the item views publish them beside the module's holo.
class ComponentHardpointTransforms < ApplicationRecord
  belongs_to :component

  # The modules this part is have their cargo holds placed from the export,
  # inside fragments keyed on the module and on the packages holding it.
  after_save :touch_model_modules, if: :saved_change_to_data?

  private def touch_model_modules
    key = component&.sc_key
    return if key.blank?

    model_modules = ModelModule.where("LOWER(sc_key) = ?", key.downcase)
    now = Time.current

    model_modules.update_all(updated_at: now)
    # A package renders its modules' holds inside its own fragment.
    ModelModulePackage.where(id: ModelModulePackageItem.where(model_module_id: model_modules.select(:id)).select(:model_module_package_id))
      .update_all(updated_at: now)
  end
end
