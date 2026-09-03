# frozen_string_literal: true

# When a ship was on sale, which nothing recorded until now.
#
# `models.on_sale` is a flag the store sync flips. It fires a notification and
# is deliberately absent from Model's paper_trail `only:` list, so every past
# sale is gone -- how often a ship goes on sale, and how long ago the last one
# was, are the questions this table exists to answer.
class CreateModelSales < ActiveRecord::Migration[8.1]
  def change
    create_table :model_sales, id: :uuid do |t|
      t.references :model, type: :uuid, null: false, foreign_key: {on_delete: :cascade}
      t.datetime :started_at, null: false
      t.datetime :ended_at

      t.timestamps
    end

    add_index :model_sales, [:model_id, :started_at], unique: true

    # A ship is either on sale or it is not, so at most one row can be open.
    # Without this a missed close leaves two open rows and every later sale is
    # measured from the wrong one.
    add_index :model_sales, :model_id,
      unique: true,
      where: "ended_at IS NULL",
      name: "index_model_sales_on_model_id_ongoing"

    add_index :model_sales, :started_at
  end
end
