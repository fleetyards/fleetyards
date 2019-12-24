class AddStarship42SlugToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :starship42_slug, :string
  end
end
