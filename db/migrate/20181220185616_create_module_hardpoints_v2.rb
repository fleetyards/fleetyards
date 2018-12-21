class CreateModuleHardpointsV2 < ActiveRecord::Migration[5.2]
  def change
    create_table :module_hardpoints, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.uuid :model_id
      t.uuid :model_module_id

      t.timestamps
    end
  end
end
