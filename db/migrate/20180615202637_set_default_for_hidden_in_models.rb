class SetDefaultForHiddenInModels < ActiveRecord::Migration[5.2]
  def change
    change_column_default :models, :hidden, true
  end
end
