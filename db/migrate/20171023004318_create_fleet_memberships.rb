class CreateFleetMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :fleet_memberships, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid :user_id
      t.uuid :fleet_id
      t.boolean :admin, default: false, null: false
      t.boolean :approved, default: false, null: false

      t.timestamps
    end
  end
end
