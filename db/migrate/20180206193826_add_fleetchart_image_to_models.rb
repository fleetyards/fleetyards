class AddFleetchartImageToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :fleetchart_image, :string
  end
end
