# frozen_string_literal: true

module Admin
  class ImagesController < ::Admin::ApplicationController
    before_action :set_active_nav

    def index
      authorize! :index, :images
      @q = Image.ransack(params[:q])
      @images = @q.result
                  .page(params.fetch(:page, nil))
                  .per(40)
    end

    private def set_active_nav
      @active_nav = 'admin-images'
    end
  end
end
