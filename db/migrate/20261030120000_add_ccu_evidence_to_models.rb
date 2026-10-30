class AddCcuEvidenceToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :ccu_source_seen_at, :datetime
    add_column :models, :ccu_target_seen_at, :datetime
    add_column :models, :ccu_on_sale, :boolean, default: false, null: false
    add_column :models, :ccu_override, :string
  end
end
