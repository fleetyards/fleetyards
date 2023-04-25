# frozen_string_literal: true

module Api
  class PublicBaseController < ::Api::BaseController
    skip_authorization_check
    before_action :authenticate_user!, only: %i[]
  end
end
