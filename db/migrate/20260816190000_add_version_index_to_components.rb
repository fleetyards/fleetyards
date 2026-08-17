class AddVersionIndexToComponents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Component.current_version narrows every picker and filter query, and
    # nothing indexed the column it reads. Built after the collapse so it goes
    # over the table that survives it rather than the one that did not.
    add_index :components, :version, algorithm: :concurrently
  end
end
