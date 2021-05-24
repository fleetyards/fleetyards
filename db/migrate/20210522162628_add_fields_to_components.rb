class AddFieldsToComponents < ActiveRecord::Migration[6.1]
  def change
    add_column :components, :type_data, :string
    add_column :components, :durability, :string
    add_column :components, :power_connection, :string
    add_column :components, :heat_connection, :string
  end
end
