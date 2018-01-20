class CreateHangarGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :hangar_groups, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.string :color
      t.uuid :user_id

      t.timestamps
    end
  end
end
