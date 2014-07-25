class AddTranslationsTableForShips < ActiveRecord::Migration
  def up
    Ship.create_translation_table!({
      description: :text
    }, {
      migrate_data: true
    })
  end

  def down
    Ship.drop_translation_table! migrate_data: true
  end
end
