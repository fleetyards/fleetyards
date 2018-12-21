class CreateUpgradeKits < ActiveRecord::Migration[5.2]
  def change
    create_table :upgrade_kits, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.uuid :model_id
      t.uuid :model_upgrade_id

      t.timestamps
    end
  end
end
