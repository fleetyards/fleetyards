class RemoveNotNullConstraintFromModels < ActiveRecord::Migration[5.2]
  def change
    reversible do
      change_column :models, :length, :decimal, precision: 15, scale: 2, default: "0.0", null: false
      change_column :models, :beam, :decimal, precision: 15, scale: 2, default: "0.0", null: false
      change_column :models, :height, :decimal, precision: 15, scale: 2, default: "0.0", null: false
      change_column :models, :mass, :decimal, precision: 15, scale: 2, default: "0.0", null: false
    end
  end
end
