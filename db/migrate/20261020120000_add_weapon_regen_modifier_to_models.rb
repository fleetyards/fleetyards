# frozen_string_literal: true

class AddWeaponRegenModifierToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :weapon_regen_modifier, :jsonb
    add_column :model_builds, :weapon_regen_modifier, :jsonb
  end
end
