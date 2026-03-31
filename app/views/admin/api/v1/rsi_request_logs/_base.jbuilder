# frozen_string_literal: true

json.id rsi_request_log.id
json.url rsi_request_log.url
json.resolved rsi_request_log.resolved
json.partial! "api/shared/dates", record: rsi_request_log
