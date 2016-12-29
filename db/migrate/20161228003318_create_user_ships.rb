class CreateUserShips < ActiveRecord::Migration
  def change
    create_table :user_ships, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.uuid :user_id
      t.uuid :ship_id
      t.string :name

      t.timestamps
    end
  end
end
