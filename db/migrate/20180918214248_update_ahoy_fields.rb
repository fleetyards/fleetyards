class UpdateAhoyFields < ActiveRecord::Migration[5.2]
  def up
    remove_column :ahoy_visits, :country
    remove_column :ahoy_visits, :region
    remove_column :ahoy_visits, :city

    remove_column :ahoy_visits, :utm_source
    remove_column :ahoy_visits, :utm_medium
    remove_column :ahoy_visits, :utm_term
    remove_column :ahoy_visits, :utm_content
    remove_column :ahoy_visits, :utm_campaign

    add_column :users, :tracking, :boolean, default: true
  end

  def down
    add_column :ahoy_visits, :country, :string
    add_column :ahoy_visits, :region, :string
    add_column :ahoy_visits, :city, :string

    add_column :ahoy_visits, :utm_source, :string
    add_column :ahoy_visits, :utm_medium, :string
    add_column :ahoy_visits, :utm_term, :string
    add_column :ahoy_visits, :utm_content, :string
    add_column :ahoy_visits, :utm_campaign, :string

    remove_column :users, :tracking
  end
end
