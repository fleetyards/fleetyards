class CreateHabitations < ActiveRecord::Migration[5.2]
  def change
    create_table :habitations, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :name
      t.integer :habitation_type
      t.references :station, type: :uuid

      t.timestamps
    end
  end
end
