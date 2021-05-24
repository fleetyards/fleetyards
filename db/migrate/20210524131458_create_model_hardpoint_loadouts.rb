class CreateModelHardpointLoadouts < ActiveRecord::Migration[6.1]
  def change
    create_table :model_hardpoint_loadouts, id: :uuid do |t|
      t.uuid :component_id
      t.uuid :model_hardpoint_id
      t.string :name

      t.timestamps
    end
  end
end
