# frozen_string_literal: true

class AddIconToManufacturers < ActiveRecord::Migration[8.1]
  def change
    add_column :manufacturers, :icon, :string
  end
end
