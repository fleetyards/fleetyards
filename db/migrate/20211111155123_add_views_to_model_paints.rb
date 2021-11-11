class AddViewsToModelPaints < ActiveRecord::Migration[6.1]
  def change
    add_column :model_paints, :top_view, :string
    add_column :model_paints, :side_view, :string
  end
end
