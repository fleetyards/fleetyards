class RemoveOldUuidExtension < ActiveRecord::Migration[6.0]
  def change
    disable_extension "uuid-ossp"
  end
end
