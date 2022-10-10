class AddHangarUpdatedAtToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :hangar_updated_at, :datetime
  end
end
