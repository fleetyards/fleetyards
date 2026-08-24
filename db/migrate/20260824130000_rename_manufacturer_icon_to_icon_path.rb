# frozen_string_literal: true

class RenameManufacturerIconToIconPath < ActiveRecord::Migration[8.1]
  def change
    rename_column :manufacturers, :icon, :icon_path
  end
end
