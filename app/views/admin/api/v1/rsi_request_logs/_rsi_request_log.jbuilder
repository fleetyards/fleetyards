# frozen_string_literal: true

json.cache! ["v1", rsi_request_log] do
  json.partial!("admin/api/v1/rsi_request_logs/base", rsi_request_log:)
end
