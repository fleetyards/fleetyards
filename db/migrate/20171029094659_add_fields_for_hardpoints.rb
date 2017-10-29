class AddFieldsForHardpoints < ActiveRecord::Migration[5.1]
  def change
    add_column :hardpoints, :default_empty, :boolean, default: false
    add_column :components, :component_type, :string
  end
end
