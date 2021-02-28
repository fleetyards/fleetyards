class RemoveStarship42SlugFromModels < ActiveRecord::Migration[6.0]
  def change
    remove_column :models, :starship42_slug, :string
    remove_column :model_paints, :starship42_slug, :string
  end
end
