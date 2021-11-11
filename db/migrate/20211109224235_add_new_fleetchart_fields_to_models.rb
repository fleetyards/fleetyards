class AddNewFleetchartFieldsToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :top_view, :string
    add_column :models, :side_view, :string
  end
end
