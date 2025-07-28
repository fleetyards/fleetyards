class AddCtmUrlToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :rsi_ctm_url, :string
  end
end
