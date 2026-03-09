# frozen_string_literal: true

json.items do
  json.array! @rsi_request_logs, partial: "admin/api/v1/rsi_request_logs/rsi_request_log", as: :rsi_request_log
end
json.partial! "api/shared/meta", result: @rsi_request_logs
