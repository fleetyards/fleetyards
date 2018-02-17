class AddLastUpdatedAtToModels < ActiveRecord::Migration[5.1]
  def change
    add_column :models, :last_updated_at, :datetime
  end
end
