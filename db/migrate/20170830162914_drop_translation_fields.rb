class DropTranslationFields < ActiveRecord::Migration[5.1]
  def up
    remove_column :ships, :description_translations
    remove_column :albums, :description_translations
    remove_column :component_categories, :name_translations
    remove_column :components, :component_type_translations
    remove_column :components, :name_translations
    remove_column :hardpoints, :name_translations
    remove_column :manufacturers, :description_translations
    remove_column :ship_roles, :name_translations
  end

  def down
    add_column :ships, :description_translations, :jsonb
    add_column :albums, :description_translations, :jsonb
    add_column :component_categories, :name_translations, :jsonb
    add_column :components, :component_type_translations, :jsonb
    add_column :components, :name_translations, :jsonb
    add_column :hardpoints, :name_translations, :jsonb
    add_column :manufacturers, :description_translations, :jsonb
    add_column :ship_roles, :name_translations, :jsonb
  end
end
