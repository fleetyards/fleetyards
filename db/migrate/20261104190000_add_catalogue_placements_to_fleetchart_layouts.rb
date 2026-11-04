# frozen_string_literal: true

class AddCataloguePlacementsToFleetchartLayouts < ActiveRecord::Migration[8.1]
  def change
    add_column :fleetchart_layouts, :catalogue_placements, :jsonb, null: false, default: []
  end
end
