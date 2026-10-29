class CreateHangarPlanVehicleMarks < ActiveRecord::Migration[8.1]
  def change
    # No foreign key on the vehicle: a plan has to notice when the live hangar
    # lost one, so the id outlives the row it pointed at.
    create_table :hangar_plan_vehicle_marks, id: :uuid do |t|
      t.references :hangar_plan, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.uuid :vehicle_id, null: false
      t.string :mark, null: false, default: "pending"
      t.timestamps
    end
    add_index :hangar_plan_vehicle_marks, [:hangar_plan_id, :vehicle_id], unique: true,
      name: "index_hangar_plan_vehicle_marks_on_plan_and_vehicle"
  end
end
