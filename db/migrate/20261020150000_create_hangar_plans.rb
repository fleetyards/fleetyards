class CreateHangarPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :hangar_plans, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.text :description
      t.datetime :based_on_at, null: false
      t.decimal :starting_credit, precision: 15, scale: 2, null: false, default: 0
      t.string :share_token
      t.timestamps
    end
    add_index :hangar_plans, [:user_id, :name], unique: true
    add_index :hangar_plans, :share_token, unique: true

    create_table :hangar_plan_slots, id: :uuid do |t|
      t.references :hangar_plan, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :label, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :hangar_plan_candidates, id: :uuid do |t|
      t.references :hangar_plan_slot, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.references :model, type: :uuid, null: false, foreign_key: true
      t.references :model_paint, type: :uuid, foreign_key: {on_delete: :nullify}, index: false
      t.uuid :model_module_ids, array: true, null: false, default: []
      t.uuid :model_upgrade_ids, array: true, null: false, default: []
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    # Source vehicles and pledges carry no foreign key: a plan has to notice
    # when the live hangar lost one, so the id outlives the row it pointed at.
    create_table :hangar_plan_acquisitions, id: :uuid do |t|
      t.references :hangar_plan, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :hangar_plan_candidate, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :start_kind, null: false
      t.uuid :source_vehicle_id
      t.uuid :buyback_pledge_id
      t.uuid :start_model_id, null: false
      t.decimal :price_override, precision: 15, scale: 2
      t.decimal :price_snapshot, precision: 15, scale: 2
      t.timestamps
    end
    add_index :hangar_plan_acquisitions, [:hangar_plan_id, :source_vehicle_id], unique: true,
      where: "source_vehicle_id IS NOT NULL", name: "index_hangar_plan_acquisitions_on_plan_and_vehicle"
    add_index :hangar_plan_acquisitions, [:hangar_plan_id, :buyback_pledge_id], unique: true,
      where: "buyback_pledge_id IS NOT NULL", name: "index_hangar_plan_acquisitions_on_plan_and_buyback"

    create_table :hangar_plan_upgrade_steps, id: :uuid do |t|
      t.references :hangar_plan, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.references :hangar_plan_acquisition, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.string :source_kind, null: false
      t.uuid :from_model_id, null: false
      t.uuid :to_model_id, null: false
      t.uuid :hangar_pledge_item_id
      t.uuid :buyback_pledge_id
      t.integer :position, null: false, default: 0
      t.decimal :price_override, precision: 15, scale: 2
      t.decimal :price_snapshot, precision: 15, scale: 2
      t.timestamps
    end
    add_index :hangar_plan_upgrade_steps, [:hangar_plan_id, :buyback_pledge_id], unique: true,
      where: "buyback_pledge_id IS NOT NULL", name: "index_hangar_plan_upgrade_steps_on_plan_and_buyback"

    create_table :hangar_plan_melts, id: :uuid do |t|
      t.references :hangar_plan, type: :uuid, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.uuid :vehicle_id, null: false
      t.uuid :model_id, null: false
      t.decimal :value_override, precision: 15, scale: 2
      t.decimal :value_snapshot, precision: 15, scale: 2
      t.timestamps
    end
    add_index :hangar_plan_melts, [:hangar_plan_id, :vehicle_id], unique: true
  end
end
