# frozen_string_literal: true

json.sid @fleet.rsi_sid
json.token @fleet.rsi_verification_token
json.status @fleet.rsi_verification_status
json.verified @fleet.rsi_verified?
json.verified_at @fleet.rsi_verified_at&.utc&.iso8601
json.checked_at @fleet.rsi_verification_checked_at&.utc&.iso8601
json.next_check_at (@fleet.rsi_verification_checked_at + Fleet::RSI_VERIFICATION_COOLDOWN).utc.iso8601 if @fleet.rsi_verification_cooling_down?
