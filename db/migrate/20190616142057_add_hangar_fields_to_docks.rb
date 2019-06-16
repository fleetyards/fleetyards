# frozen_string_literal: true

class AddHangarFieldsToDocks < ActiveRecord::Migration[5.2]
  def change
    add_column :docks, :height, :decimal, precision: 15, scale: 2
    add_column :docks, :beam, :decimal, precision: 15, scale: 2
    add_column :docks, :length, :decimal, precision: 15, scale: 2
  end
end
