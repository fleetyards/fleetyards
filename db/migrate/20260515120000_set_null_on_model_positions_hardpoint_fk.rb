# frozen_string_literal: true

class SetNullOnModelPositionsHardpointFk < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :model_positions, :hardpoints
    add_foreign_key :model_positions, :hardpoints, on_delete: :nullify
  end
end
