class AddTranslationTables < ActiveRecord::Migration
  def up
    Ship.create_translation_table! description: :text
    Component.create_translation_table! name: :string, component_type: :string
    ComponentCategory.create_translation_table! name: :string
    Hardpoint.create_translation_table! name: :string
    ShipRole.create_translation_table! name: :string
    Manufacturer.create_translation_table! description: :text
    Album.create_translation_table! description: :text
  end

  def down
    Ship.drop_translation_table!
    Equipment.drop_translation_table!
    Hardpoint.drop_translation_table!
    ShipRole.drop_translation_table!
    Manufacturer.drop_translation_table!
    Album.drop_translation_table!
  end
end
