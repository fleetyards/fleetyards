class AddDimensionsToImages < ActiveRecord::Migration[5.2]
  def change
    add_column :images, :width, :integer
    add_column :images, :height, :integer
  end
end
