class AddFleetchartViewsForModulePackages < ActiveRecord::Migration[6.1]
  def change
    add_column :model_module_packages, :angled_view, :string
    add_column :model_module_packages, :angled_view_height, :integer
    add_column :model_module_packages, :angled_view_width, :integer
    add_column :model_module_packages, :top_view, :string
    add_column :model_module_packages, :top_view_height, :integer
    add_column :model_module_packages, :top_view_width, :integer
    add_column :model_module_packages, :side_view, :string
    add_column :model_module_packages, :side_view_height, :integer
    add_column :model_module_packages, :side_view_width, :integer
  end
end
