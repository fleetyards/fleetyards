class CreateFactions < ActiveRecord::Migration[5.2]
  def change
    create_table :factions, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.integer :rsi_id
      t.string :name
      t.string :slug
      t.string :code
      t.string :color

      t.timestamps
    end
  end
end
