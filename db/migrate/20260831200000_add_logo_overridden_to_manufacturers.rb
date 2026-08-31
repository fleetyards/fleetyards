# frozen_string_literal: true

class AddLogoOverriddenToManufacturers < ActiveRecord::Migration[8.1]
  def change
    add_column :manufacturers, :logo_overridden, :boolean, default: false, null: false
  end
end
