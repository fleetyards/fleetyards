class AddAngledViewToModelPaints < ActiveRecord::Migration[6.1]
  def change
    add_column :model_paints, :angled_view, :string
  end
end
