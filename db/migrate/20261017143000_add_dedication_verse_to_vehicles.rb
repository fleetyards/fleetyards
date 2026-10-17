# frozen_string_literal: true

class AddDedicationVerseToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :dedication_verse, :text
  end
end
