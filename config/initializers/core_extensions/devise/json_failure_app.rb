# frozen_string_literal: true

class JSONFailureApp < Devise::FailureApp
  def self.call(env)
    # FIXUP warden PATH_INFO rewrite to /unauthenticated
    env['PATH_INFO'] = env['ORIGINAL_FULLPATH']
    super
  end

  def respond
    if request.format == :json
      json_failure
    else
      super
    end
  end

  def json_failure
    self.status = 401
    self.content_type = "application/json"
    self.response_body = { code: "unauthorized", message: I18n.t("devise.failure.unauthenticated") }.to_json
  end
end
