class AddScDataFieldsToComponents < ActiveRecord::Migration[7.1]
  def change
    add_column :components, :hidden, :boolean, default: false
    add_column :components, :sc_key, :string
    add_column :components, :sc_ref, :string
    add_column :components, :category, :string
    add_column :components, :component_type, :string
    add_column :components, :component_sub_type, :string
    add_column :components, :inventory_consumption, :string
  end
end
