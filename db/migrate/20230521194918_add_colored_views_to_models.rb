class AddColoredViewsToModels < ActiveRecord::Migration[7.0]
  def change
    add_column :models, :angled_view_colored, :string
    add_column :models, :angled_view_colored_width, :integer
    add_column :models, :angled_view_colored_height, :integer
    add_column :models, :side_view_colored, :string
    add_column :models, :side_view_colored_width, :integer
    add_column :models, :side_view_colored_height, :integer
    add_column :models, :top_view_colored, :string
    add_column :models, :top_view_colore_width, :integer
    add_column :models, :top_view_colore_height, :integer
    add_column :models, :front_view_colored, :string
    add_column :models, :front_view_colored_width, :integer
    add_column :models, :front_view_colored_height, :integer
  end
end
