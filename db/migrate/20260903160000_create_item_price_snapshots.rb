# frozen_string_literal: true

# What the UEX feed said a thing cost on a given day.
#
# `item_prices` is a snapshot the daily sync overwrites in place, so yesterday's
# prices do not exist anywhere. One row per item, terminal and price type per
# day is what turns that into a history.
class CreateItemPriceSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :item_price_snapshots, id: :uuid do |t|
      t.references :item, type: :uuid, polymorphic: true, null: false
      t.string :location, null: false
      t.integer :price_type, null: false
      t.integer :time_range
      t.decimal :price, precision: 15, scale: 2, null: false
      t.date :recorded_on, null: false

      t.timestamps
    end

    # Mirrors the key `ItemPrice` itself is unique on, plus the day. Rentals
    # carry a `time_range` and everything else leaves it null, so the index has
    # to treat two nulls as equal or it would let a day be recorded twice.
    add_index :item_price_snapshots,
      %i[item_type item_id location price_type time_range recorded_on],
      unique: true,
      nulls_not_distinct: true,
      name: "index_item_price_snapshots_on_item_and_day"

    add_index :item_price_snapshots, %i[item_type item_id recorded_on],
      name: "index_item_price_snapshots_on_item_and_recorded_on"

    # Retention deletes by date across every item type.
    add_index :item_price_snapshots, :recorded_on
  end
end
