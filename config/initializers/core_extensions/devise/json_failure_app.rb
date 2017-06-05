# encoding: utf-8
# frozen_string_literal: true

class JSONFailureApp < Devise::FailureApp
  def respond
    if request.format == :json
      json_failure
    else
      super
    end
  end

  def json_failure
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { code: "unauthorized", message: i18n_message }.to_json
  end
end
