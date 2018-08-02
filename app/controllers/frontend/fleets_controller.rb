# frozen_string_literal: true

module Frontend
  class FleetsController < ApplicationController
    def index
      @title = I18n.t('title.frontend.fleets')
      render 'frontend/index'
    end

    def show
      @fleet = Fleet.find_by(sid: params[:sid])
      if @fleet.present?
        @title = @fleet.name
        @og_type = 'article'
        @og_image = @fleet.logo
      end
      render 'frontend/index'
    end
  end
end
