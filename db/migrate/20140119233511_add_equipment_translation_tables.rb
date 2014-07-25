class AddEquipmentTranslationTables < ActiveRecord::Migration
  def up
    Equipment.create_translation_table! description: :text
    Hardpoint.create_translation_table! description: :text
    Weapon.create_translation_table! description: :text
  end

  def down
    Equipment.drop_translation_table!
    Hardpoint.drop_translation_table!
    Weapon.drop_translation_table!
  end
end
