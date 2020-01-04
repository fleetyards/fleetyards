class CreateFleets < ActiveRecord::Migration[5.2]
  def change
    create_table :fleets, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade  do |t|
      t.string :name
      t.string :slug
      t.string :sid
      t.string :logo
      t.string :background_image
      t.uuid :created_by

      t.timestamps
    end
  end
end
