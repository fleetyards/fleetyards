# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[
  email password username rsi_handle token otp_attempt two_factor_code passw
  secret _key crypt salt certificate otp ssn
]
