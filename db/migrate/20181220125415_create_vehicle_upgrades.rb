class CreateVehicleUpgrades < ActiveRecord::Migration[5.2]
  def change
    create_table :vehicle_upgrades, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.uuid :model_upgrade_id
      t.uuid :vehicle_id

      t.timestamps
    end
  end
end
