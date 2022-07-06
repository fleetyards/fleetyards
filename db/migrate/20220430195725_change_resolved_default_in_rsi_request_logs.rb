class ChangeResolvedDefaultInRsiRequestLogs < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:rsi_request_logs, :resolved, false)

    RsiRequestLog.where(resolved: nil).find_each do |rsi_request_log|
      rsi_request_log.update(resolved: false)
    end
  end
end
