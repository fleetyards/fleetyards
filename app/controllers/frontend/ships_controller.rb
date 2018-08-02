# frozen_string_literal: true

module Frontend
  class ShipsController < ApplicationController
    def index
      @title = I18n.t('title.frontend.models')
      render 'frontend/index'
    end

    def show
      @model = Model.find_by(slug: params[:slug])
      if @model.present?
        @title = @model.name
        @description = @model.description
        @og_type = 'article'
        @og_image = @model.store_image.url
      end
      render 'frontend/index'
    end
  end
end
