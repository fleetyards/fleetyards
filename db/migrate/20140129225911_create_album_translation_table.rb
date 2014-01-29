class CreateAlbumTranslationTable < ActiveRecord::Migration
  def up
    Album.create_translation_table! description: :text
  end

  def down
    Album.drop_translation_table!
  end
end
