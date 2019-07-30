class AddCommodityTypeToCommodities < ActiveRecord::Migration[5.2]
  def change
    add_column :commodities, :commodity_type, :integer
  end
end
