# frozen_string_literal: true

module Frontend
  class BaseController < ApplicationController
    def index
      render 'frontend/index'
    end

    def home
      @title = I18n.t('title.frontend.home')
      render 'frontend/index'
    end

    def cargo
      @title = I18n.t('title.frontend.cargo')
      render 'frontend/index'
    end

    def commodities
      @title = I18n.t('title.frontend.commodities')
      render 'frontend/index'
    end

    def impressum
      @title = I18n.t('title.frontend.impressum')
      render 'frontend/index'
    end

    def privacy
      @title = I18n.t('title.frontend.privacy')
      render 'frontend/index'
    end

    def login
      @title = I18n.t('title.frontend.login')
      render 'frontend/index'
    end

    def signup
      @title = I18n.t('title.frontend.sign_up')
      render 'frontend/index'
    end

    def password_request
      @title = I18n.t('title.frontend.password_request')
      render 'frontend/index'
    end

    def images
      @title = I18n.t('title.frontend.images')
      render 'frontend/index'
    end

    def embed
      redirect_to ActionController::Base.helpers.asset_url(Webpacker.manifest.lookup!('embed.js'))
    end
  end
end
