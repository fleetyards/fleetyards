class ChangeDataSlugInModels < ActiveRecord::Migration[6.0]
  def change
    rename_column :models, :data_slug, :sc_identifier
    rename_column :components, :data_slug, :sc_identifier
  end
end
