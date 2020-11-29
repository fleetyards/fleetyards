class ChangeFieldInModels < ActiveRecord::Migration[6.0]
  def change
    rename_column :models, :erkuls_slug, :data_slug
  end
end
