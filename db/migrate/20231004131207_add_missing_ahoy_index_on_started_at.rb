class AddMissingAhoyIndexOnStartedAt < ActiveRecord::Migration[7.0]
  def change
    add_index :ahoy_visits, [:visitor_token, :started_at]
  end
end
