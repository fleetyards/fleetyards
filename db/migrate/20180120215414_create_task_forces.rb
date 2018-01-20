class CreateTaskForces < ActiveRecord::Migration[5.1]
  def change
    create_table :task_forces, id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid :vehicle_id
      t.uuid :hangar_group_id

      t.timestamps
    end
  end
end
