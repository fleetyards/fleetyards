class AddMapToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :adi_map, :boolean, default: false
  end
end
