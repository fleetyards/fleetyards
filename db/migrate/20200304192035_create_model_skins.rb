# frozen_string_literal: true

class CreateModelSkins < ActiveRecord::Migration[6.0]
  def change
    create_table :model_skins, id: :uuid, default: -> { 'uuid_generate_v4()' }, force: :cascade do |t|
      t.string :name
      t.uuid :model_id
      t.string :slug
      t.string :description
      t.decimal :pledge_price, precision: 15, scale: 2
      t.decimal :last_pledge_price, precision: 15, scale: 2
      t.string :store_image
      t.boolean :active, default: true
      t.boolean :hidden, default: true
      t.datetime :store_images_updated_at
      t.string :store_url
      t.string :starship42_slug
      t.integer :rsi_id
      t.string :rsi_name
      t.string :rsi_slug
      t.string :rsi_description
      t.string :rsi_store_url
      t.datetime :last_updated_at
      t.boolean :on_sale, default: false
      t.string :production_status
      t.string :production_note

      t.timestamps
    end
  end
end
