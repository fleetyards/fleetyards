# frozen_string_literal: true

class MakeSupporterContributionNameNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :supporter_contributions, :name, true
  end
end
