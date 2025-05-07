class CreateFleetRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :fleet_roles, id: :uuid do |t|
      t.string :name
      t.string :slug
      t.text :rank
      t.text :resource_access
      t.references :fleet, null: false, foreign_key: true, type: :uuid
      t.boolean :permanent
      t.index %i[fleet_id rank], unique: true
      t.timestamps
    end

    add_reference :fleet_memberships, :fleet_role, null: true, foreign_key: true, type: :uuid
  end
end
