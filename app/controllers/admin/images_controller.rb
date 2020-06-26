# frozen_string_literal: true

module Admin
  class ImagesController < ::Admin::ApplicationController
    before_action :set_active_nav

    def index
      authorize! :index, :images
      @app_enabled = true
    end

    private def set_active_nav
      @active_nav = 'admin-images'
    end
  end
end
