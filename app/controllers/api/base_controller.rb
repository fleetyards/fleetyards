# encoding: utf-8
# frozen_string_literal: true

module Api
  class BaseController < ActionController::Base
    include Concerns::Pagination

    protect_from_forgery with: :null_session

    before_action :authenticate_user!

    respond_to :json

    check_authorization

    rescue_from CanCan::AccessDenied do |exception|
      render json: { message: exception.message }, status: :forbidden
    end

    def resource_message(resource, action, state)
      I18n.t(state, scope: "resources.messages.#{action}", resource: I18n.t(:"resources.#{resource}"))
    end
    helper_method :resource_message
  end
end
