# frozen_string_literal: true

class AddFieldsToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :rsi_height, :decimal, precision: 15, scale: 2, default: '0.0', null: false
    add_column :models, :rsi_length, :decimal, precision: 15, scale: 2, default: '0.0', null: false
    add_column :models, :rsi_beam, :decimal, precision: 15, scale: 2, default: '0.0', null: false
    add_column :models, :rsi_cargo, :decimal, precision: 15, scale: 2
  end
end
