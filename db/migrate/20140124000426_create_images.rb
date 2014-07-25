class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :name
      t.integer :gallery_id
      t.string :gallery_type

      t.timestamps
    end
  end
end
