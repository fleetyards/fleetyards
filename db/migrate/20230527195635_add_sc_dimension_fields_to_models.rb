class AddScDimensionFieldsToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :sc_length, :decimal, precision: 15, scale: 2
    add_column :models, :sc_beam, :decimal, precision: 15, scale: 2
    add_column :models, :sc_height, :decimal, precision: 15, scale: 2
  end
end
