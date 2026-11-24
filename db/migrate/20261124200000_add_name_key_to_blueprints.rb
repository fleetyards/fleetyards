# frozen_string_literal: true

class AddNameKeyToBlueprints < ActiveRecord::Migration[8.1]
  def change
    add_column :blueprints, :name_key, :string
  end
end
