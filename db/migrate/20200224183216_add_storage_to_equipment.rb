# frozen_string_literal: true

class AddStorageToEquipment < ActiveRecord::Migration[6.0]
  def change
    add_column :equipment, :storage, :decimal, precision: 15, scale: 2
  end
end
