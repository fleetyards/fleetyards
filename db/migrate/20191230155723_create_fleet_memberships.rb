class CreateFleetMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :fleet_memberships, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade  do |t|
      t.uuid :fleet_id
      t.uuid :user_id
      t.integer :role
      t.datetime :accepted_at
      t.datetime :declined_at

      t.timestamps
    end
  end
end
