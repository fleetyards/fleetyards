# frozen_string_literal: true

class AddCoverImagePresetToMissions < ActiveRecord::Migration[7.2]
  def change
    add_column :missions, :cover_image_preset, :string
  end
end
