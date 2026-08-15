class CreateCommodities < ActiveRecord::Migration[8.1]
  def change
    create_table :commodities, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      # Nullable: a commodity can also come from UEX, which lists goods the
      # game files don't declare.
      t.string :sc_key
      t.string :sc_ref
      t.string :name, null: false
      t.string :slug, null: false
      t.string :commodity_type
      t.text :description
      t.string :icon
      t.string :version
      t.integer :uex_id
      t.string :uex_slug
      t.timestamps

      t.index :sc_key, unique: true
      t.index :slug, unique: true
      t.index :commodity_type
      t.index :uex_slug
    end
  end
end
