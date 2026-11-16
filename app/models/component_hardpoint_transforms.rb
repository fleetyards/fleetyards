# frozen_string_literal: true

# Where on a module's hull holo each of its item ports sits, and how its doors
# open, as the item views publish them beside the module's holo.
class ComponentHardpointTransforms < ApplicationRecord
  belongs_to :component

  # The modules this part is have their cargo holds placed from the export,
  # inside fragments keyed on the module.
  after_save :touch_model_modules, if: :saved_change_to_data?

  private def touch_model_modules
    key = component&.sc_key
    return if key.blank?

    ModelModule.where("LOWER(sc_key) = ?", key.downcase).update_all(updated_at: Time.current)
  end
end
