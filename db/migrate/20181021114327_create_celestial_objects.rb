class CreateCelestialObjects < ActiveRecord::Migration[5.2]
  def change
    create_table :celestial_objects, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :name
      t.string :slug
      t.references :starsystem, type: :uuid
      t.string :object_type
      t.integer :rsi_id
      t.string :code
      t.string :status
      t.string :designation
      t.datetime :last_updated_at
      t.text :description
      t.boolean :hidden, default: true
      t.string :orbit_period
      t.boolean :habitable
      t.boolean :fairchanceact
      t.integer :sensor_population
      t.integer :sensor_economy
      t.integer :sensor_danger
      t.string :size
      t.string :sub_type
      t.string :store_image
      t.uuid :parent_id

      t.timestamps
    end
  end
end
