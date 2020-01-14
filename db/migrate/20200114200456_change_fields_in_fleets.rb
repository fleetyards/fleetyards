class ChangeFieldsInFleets < ActiveRecord::Migration[5.2]
  def change
    rename_column :fleets, :name, :fid
  end
end
