class AddIndicesForStatsQueries < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # vehicles: stats queries filter on visible + loaner
    add_index :vehicles, [:hidden, :loaner], algorithm: :concurrently

    # models: group by columns used in stats charts
    add_index :models, :classification, algorithm: :concurrently
    add_index :models, :size, algorithm: :concurrently
    add_index :models, :production_status, algorithm: :concurrently
    add_index :models, :manufacturer_id, algorithm: :concurrently
    add_index :models, :name, algorithm: :concurrently
  end
end
