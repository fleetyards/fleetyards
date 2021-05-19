class AddSubmittersToCommodityPrices < ActiveRecord::Migration[6.1]
  def up
    add_column :commodity_prices, :submitters, :string

    CommodityPrice.where.not(submitted_by: nil).find_each do |price|
      price.update(submitters: [price.submitted_by])
    end

    remove_column :commodity_prices, :submitted_by
  end

  def down
    add_column :commodity_prices, :submitted_by, :uuid

    CommodityPrice.where.not(submitters: nil).find_each do |price|
      price.update(submitted_by: price.submitters.first)
    end

    remove_column :commodity_prices, :submitters, :string
  end
end
