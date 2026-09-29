# frozen_string_literal: true

# The schema promises every key, null or not.
json.ignore_nil! false

json.handle @user.rsi_handle
json.token @user.rsi_verification_token
json.status @user.rsi_verification_status
json.verified @user.rsi_handle_verified
json.verified_via @user.rsi_handle_verified_via
json.verified_at @user.rsi_handle_verified_at&.utc&.iso8601
json.checked_at @user.rsi_verification_checked_at&.utc&.iso8601
json.next_check_at (@user.rsi_verification_checked_at + User::RSI_VERIFICATION_COOLDOWN).utc.iso8601(6) if @user.rsi_verification_cooling_down?
