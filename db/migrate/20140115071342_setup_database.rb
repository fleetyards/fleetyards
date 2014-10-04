class SetupDatabase < ActiveRecord::Migration
  def change
    enable_extension "hstore"
    enable_extension "uuid-ossp"

    create_table :worker_states, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.boolean :running, default: false
      t.datetime :last_run_start
      t.datetime :last_run_end

      t.timestamps
    end

    create_table :users, id: :uuid, default: "uuid_generate_v4()", force: true do |t|

      t.boolean :admin, null: false, default: false
      t.hstore  :profile
      t.hstore  :settings
      t.string  :gravatar_hash
      t.string  :gravatar
      t.string  :locale

      ## Database authenticatable
      t.string :username,           null: false, default: ""
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :username,             unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true

    create_table :ships, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :length
      t.string :beam
      t.string :height
      t.string :mass
      t.string :cargo
      t.string :crew
      t.string :image
      t.string :store_image
      t.string :store_url
      t.integer :powerplant_size
      t.integer :shield_size
      t.string :classification
      t.boolean :enabled, null: false, default: false

      t.integer :rsi_id

      t.uuid :manufacturer_id
      t.uuid :ship_role_id

      t.text :propulsion_raw
      t.text :ordnance_raw
      t.text :modular_raw
      t.text :avionics_raw

      t.timestamps
    end

    create_table :ship_roles, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end

    create_table :manufacturers, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :slug
      t.string :known_for
      t.text :description
      t.string :logo
      t.boolean :enabled, null: false, default: false

      t.integer :rsi_id

      t.timestamps
    end

    create_table :component_categories, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :rsi_name
      t.string :name
      t.string :slug
    end

    create_table :components, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :size
      t.string :component_type
      t.boolean :enabled, null: false, default: false

      t.integer :rsi_id

      t.uuid :category_id

      t.timestamps
    end

    create_table :hardpoints, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :hardpoint_class
      t.integer :rating
      t.integer :max_size
      t.integer :quantity

      t.integer :rsi_id

      t.uuid :category_id
      t.uuid :ship_id
      t.uuid :component_id

      t.timestamps
    end

    create_table :images, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.uuid :gallery_id
      t.string :gallery_type
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end

    create_table :albums, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :slug
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end

  end
end
