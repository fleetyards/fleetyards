class AddErkulsSlugToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :erkuls_slug, :string
  end
end
