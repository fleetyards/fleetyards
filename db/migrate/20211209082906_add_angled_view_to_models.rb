class AddAngledViewToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :angled_view, :string
  end
end
