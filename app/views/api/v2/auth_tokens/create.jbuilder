# frozen_string_literal: true

json.token @token
json.partial!("api/v2/auth_tokens/minimal", auth_token:)
