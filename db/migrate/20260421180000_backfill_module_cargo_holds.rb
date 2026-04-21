# frozen_string_literal: true

class BackfillModuleCargoHolds < ActiveRecord::Migration[7.2]
  def up
    ModelModule.where.not(cargo_holds: nil).find_each do |mod|
      next if mod.cargo_holds.blank?

      mod.update_cargo_holds_db

      total = mod.cargo_holds.sum { |h| h["capacity"]&.to_f || 0 }
      mod.update_column(:cargo, total) if mod.cargo != total
    end
  end

  def down
    CargoHold.where(parent_type: "ModelModule").destroy_all
  end
end
