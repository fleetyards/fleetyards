class DropFleets < ActiveRecord::Migration[5.2]
  def up
    drop_table :fleets

    remove_column :users, :rsi_org, :string
    remove_column :users, :rsi_orgs, :string
    remove_column :users, :rsi_verification_token, :string
  end

  def down
    add_column :users, :rsi_org, :string
    add_column :users, :rsi_orgs, :string
    add_column :users, :rsi_verification_token, :string

    create_table "fleets", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "name"
      t.string "logo"
      t.string "sid"
      t.string "archetype"
      t.string "main_activity"
      t.string "secondary_activity"
      t.boolean "recruiting"
      t.string "commitment"
      t.boolean "rpg"
      t.boolean "exclusive"
      t.integer "member_count"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.hstore "rsi_members", default: [], null: false, array: true
      t.string "banner"
      t.string "background"
    end
  end
end
