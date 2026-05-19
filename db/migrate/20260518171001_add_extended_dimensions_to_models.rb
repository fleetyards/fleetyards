class AddExtendedDimensionsToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :extended_length, :decimal, precision: 15, scale: 2
    add_column :models, :extended_beam, :decimal, precision: 15, scale: 2
    add_column :models, :extended_height, :decimal, precision: 15, scale: 2
    add_column :models, :extended_fleetchart_offset_length, :decimal, precision: 15, scale: 2
    add_column :models, :extended_fleetchart_offset_beam, :decimal, precision: 15, scale: 2
  end
end
