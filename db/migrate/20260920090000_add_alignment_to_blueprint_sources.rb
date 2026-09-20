# frozen_string_literal: true

class AddAlignmentToBlueprintSources < ActiveRecord::Migration[8.1]
  def change
    add_column :blueprint_sources, :alignment, :string
  end
end
