# frozen_string_literal: true

class JSONFailureApp < Devise::FailureApp
  def respond
    if request.format.json? || is_api_controller?
      json_failure
    else
      super
    end
  end

  def json_failure
    self.status = 401
    self.content_type = "application/json"
    self.response_body = {code: "unauthorized", message: I18n.t("devise.failure.unauthenticated")}.to_json
  end

  private def is_api_controller?
    request.controller_class.ancestors.include?(Admin::Api::BaseController) ||
      request.controller_class.ancestors.include?(Api::BaseController)
  end
end
