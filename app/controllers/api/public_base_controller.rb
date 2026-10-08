# frozen_string_literal: true

module Api
  class PublicBaseController < ::Api::BaseController
    before_action :authenticate_user!, only: %i[]

    authorize :share_token, through: :share_token_param

    rescue_from ActionPolicy::Unauthorized do |exception|
      not_found
    end

    private def share_token_param
      params[:share].presence
    end
  end
end
