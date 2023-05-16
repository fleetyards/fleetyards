class AddFrontViewToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :front_view, :string
    add_column :models, :front_view_width, :integer
    add_column :models, :front_view_height, :integer
  end
end
