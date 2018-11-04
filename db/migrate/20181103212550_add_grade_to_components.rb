class AddGradeToComponents < ActiveRecord::Migration[5.2]
  def change
    add_column :components, :grade, :string
    add_column :components, :item_class, :integer
    rename_column :components, :component_type, :item_type
  end
end
