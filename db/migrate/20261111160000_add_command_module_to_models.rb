# frozen_string_literal: true

class AddCommandModuleToModels < ActiveRecord::Migration[8.1]
  def change
    add_reference :models, :command_module,
      type: :uuid,
      foreign_key: {to_table: :models, on_delete: :nullify},
      index: true
  end
end
