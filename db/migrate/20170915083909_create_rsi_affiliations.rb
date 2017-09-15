class CreateRsiAffiliations < ActiveRecord::Migration[5.1]
  def change
    create_table :rsi_affiliations, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid :user_id
      t.uuid :rsi_org_id
      t.boolean :main, default: false

      t.timestamps
    end
  end
end
