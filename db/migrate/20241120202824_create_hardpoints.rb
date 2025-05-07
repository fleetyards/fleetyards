class CreateHardpoints < ActiveRecord::Migration[7.1]
  def change
    create_table :hardpoints, id: :uuid do |t|
      t.string :sc_key
      t.integer :min_size
      t.integer :max_size
      t.string :types
      t.references :parent, polymorphic: true, null: false, type: :uuid, index: true
      t.references :component, foreign_key: true, type: :uuid, index: true

      t.timestamps
    end
  end
end
