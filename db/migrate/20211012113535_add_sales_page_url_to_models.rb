class AddSalesPageUrlToModels < ActiveRecord::Migration[6.1]
  def change
    add_column :models, :sales_page_url, :string
  end
end
