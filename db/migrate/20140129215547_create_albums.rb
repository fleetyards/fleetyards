class CreateAlbums < ActiveRecord::Migration
  def change
    create_table :albums do |t|
      t.string :name
      t.string :slug
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end
  end
end
