class AddCurrentSystemToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :current_system, :string
    add_column :users, :current_system_code, :string
  end
end
