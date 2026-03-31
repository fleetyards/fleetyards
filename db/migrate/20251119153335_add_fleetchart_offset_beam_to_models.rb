class AddFleetchartOffsetBeamToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :fleetchart_offset_beam, :decimal, precision: 15, scale: 2
  end
end
