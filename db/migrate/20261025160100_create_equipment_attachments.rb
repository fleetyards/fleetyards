# frozen_string_literal: true

# Which attachments fit which port of a weapon, as one build of the game states
# it. Hung off the weapon's build for the reason blueprint sources are: live and
# ptu are loaded separately, and `prune_builds` drops a build with `delete_all`,
# so the cascade is what carries its attachments away with it.
class CreateEquipmentAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :equipment_attachments, id: :uuid do |t|
      t.references :equipment_build, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: false
      t.references :attachment, type: :uuid, null: false,
        foreign_key: {to_table: :equipment, on_delete: :cascade}

      # The port's own name (magazine_attach, optics_attach) and the first
      # attachment subtype it takes, which is what a reader groups by: a
      # launcher has three missile ports that take the same thing.
      t.string :port_name, null: false
      t.string :port_type, null: false

      # What the weapon ships with in this port.
      t.boolean :default, null: false, default: false

      t.timestamps
    end

    # Leads with the build, so it also serves a build's own lookup.
    add_index :equipment_attachments, [:equipment_build_id, :port_name, :attachment_id],
      unique: true, name: "index_equipment_attachments_uniqueness"
  end
end
