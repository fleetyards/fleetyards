# frozen_string_literal: true

class AddBackgroundToFleetchartLayouts < ActiveRecord::Migration[8.1]
  def change
    add_column :fleetchart_layouts, :background, :string, null: false, default: "dark"
  end
end
