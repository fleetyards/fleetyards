class CreateImports < ActiveRecord::Migration[6.1]
  def change
    create_table :imports, id: :uuid do |t|
      t.string :type, nil: false
      t.string :version, nil: false
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :failed_at
      t.string :aasm_state, nil: false
      t.text :info

      t.timestamps
    end
  end
end
