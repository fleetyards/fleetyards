class AddSubmissionCountToCommodityPrices < ActiveRecord::Migration[6.1]
  def up
    add_column :commodity_prices, :submission_count, :integer, default: 0

    CommodityPrice.where.not(submitted_by: nil).find_each do |price|
      price.update(submission_count: 1)
    end
  end

  def down
    remove_column :commodity_prices, :submission_count
  end
end
