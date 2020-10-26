class CreateRsiRequestLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :rsi_request_logs, id: :uuid do |t|
      t.string :url
      t.boolean :resolved

      t.timestamps
    end
  end
end
