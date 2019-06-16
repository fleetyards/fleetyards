# frozen_string_literal: true

class AddDockSizeToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :dock_size, :integer
  end
end
