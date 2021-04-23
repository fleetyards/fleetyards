# frozen_string_literal: true

module Admin2
  class BaseController < ::Admin2::ApplicationController
    layout 'admin2/application'

    def dashboard
      authorize! :show, :admin
      @active_nav = 'admin'
    end
  end
end
