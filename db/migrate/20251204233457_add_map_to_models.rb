class AddMapToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :map, :boolean, default: false
  end
end
