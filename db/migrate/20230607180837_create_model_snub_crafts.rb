class CreateModelSnubCrafts < ActiveRecord::Migration[7.0]
  def change
    create_table :model_snub_crafts, id: :uuid do |t|
      t.uuid :model_id, foreign_key: true, null: false
      t.uuid :snub_craft_id, foreign_key: true, null: false

      t.timestamps
    end
  end
end
