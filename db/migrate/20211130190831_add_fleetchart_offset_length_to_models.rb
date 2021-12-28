class AddFleetchartOffsetLengthToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :fleetchart_offset_length, :decimal, precision: 15, scale: 2
  end
end
