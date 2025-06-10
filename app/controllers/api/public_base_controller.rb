# frozen_string_literal: true

module Api
  class PublicBaseController < ::Api::BaseController
    before_action :authenticate_user!, only: %i[]

    rescue_from ActionPolicy::Unauthorized do |exception|
      not_found
    end
  end
end
