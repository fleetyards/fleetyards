class AddNameSlugToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :name_slug, :string
  end
end
