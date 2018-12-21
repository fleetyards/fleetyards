class CreateVehicleModules < ActiveRecord::Migration[5.2]
  def change
    create_table :vehicle_modules, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.uuid :model_module_id
      t.uuid :vehicle_id

      t.timestamps
    end
  end
end
