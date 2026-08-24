# frozen_string_literal: true

class AddIconOverriddenToManufacturers < ActiveRecord::Migration[8.1]
  def change
    add_column :manufacturers, :icon_overridden, :boolean, default: false, null: false
  end
end
