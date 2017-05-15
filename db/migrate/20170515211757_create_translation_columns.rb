class CreateTranslationColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :albums, :description_translations, 'jsonb'
    drop_table :album_translations

    add_column :component_categories, :name_translations, 'jsonb'
    drop_table :component_category_translations

    add_column :components, :name_translations, 'jsonb'
    add_column :components, :component_type_translations, 'jsonb'
    drop_table :component_translations

    add_column :hardpoints, :name_translations, 'jsonb'
    drop_table :hardpoint_translations

    add_column :manufacturers, :description_translations, 'jsonb'
    drop_table :manufacturer_translations

    add_column :ship_roles, :name_translations, 'jsonb'
    drop_table :ship_role_translations

    add_column :ships, :description_translations, 'jsonb'
    drop_table :ship_translations
  end
end
