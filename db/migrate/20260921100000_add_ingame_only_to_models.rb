# frozen_string_literal: true

class AddIngameOnlyToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :ingame_only, :boolean, default: false, null: false
  end
end
