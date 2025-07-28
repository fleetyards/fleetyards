class RenameScKeyInHardpoints < ActiveRecord::Migration[7.1]
  def change
    rename_column :hardpoints, :sc_key, :sc_name
  end
end
