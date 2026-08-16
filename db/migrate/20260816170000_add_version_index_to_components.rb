class AddVersionIndexToComponents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Component.current_version narrows every picker and filter query to the
    # build the game currently ships, over a table that has been collecting a
    # row per component per import with nothing to index the filter.
    add_index :components, :version, algorithm: :concurrently
  end
end
