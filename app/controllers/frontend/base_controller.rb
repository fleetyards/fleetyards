# frozen_string_literal: true

module Frontend
  class BaseController < ApplicationController
    protect_from_forgery except: :service_worker
    def index
      route = request.fullpath.split('?').first.sub(%r{^\/}, '').tr('/', '_')
      route = 'home' if route.blank?

      @title = I18n.t("title.frontend.#{route}")

      render 'frontend/index'
    end

    def password
      @title = I18n.t('title.frontend.password_change')
      render 'frontend/index'
    end

    def commodities
      @title = I18n.t('title.frontend.commodities')
      render 'frontend/index'
    end

    def fleet
      @fleet = Fleet.find_by(['lower(sid) = :value', { value: params[:sid].downcase }])
      if @fleet.present?
        @title = @fleet.name
        @og_type = 'article'
        @og_image = @fleet.logo
      end
      render 'frontend/index'
    end

    def hangar
      @user = User.find_by(['lower(username) = :value', { value: params[:username].downcase }])
      if @user.present?
        vehicle = @user.vehicles.purchased.includes(:model).order(flagship: :desc, name: :asc).order('models.name asc').first
        @title = I18n.t('title.frontend.public_hangar', user: username(@user.username))
        @og_type = 'article'
        @og_image = vehicle.model.store_image.url if vehicle.present?
      end
      render 'frontend/index'
    end

    def model
      @model = Model.find_by(['lower(slug) = :value', { value: params[:slug].downcase }])
      if @model.present?
        @title = "#{@model.name} - #{@model.manufacturer.name}"
        @description = @model.description
        @og_type = 'article'
        @og_image = @model.store_image.url
      end
      render 'frontend/index'
    end

    def not_found
      respond_to do |format|
        format.html do
          render 'frontend/index', status: :not_found
        end
        format.json do
          render json: { code: 'not_found', message: 'Not Found' }, status: :not_found
        end
      end
    end

    def embed
      redirect_to ActionController::Base.helpers.asset_url(Webpacker.manifest.lookup!('embed.js'))
    end

    def embed_styles
      redirect_to ActionController::Base.helpers.asset_url(Webpacker.manifest.lookup!('embed.css'))
    end

    def embed_test
      render 'frontend/embed_test', layout: 'embed_test'
    end

    def service_worker
      respond_to do |format|
        format.js do
          render 'frontend/service_worker', layout: false
        end
      end
    end

    private def username(name)
      if name.ends_with?('s') || name.ends_with?('x') || name.ends_with?('z')
        return name
      end
      "#{name}'s"
    end
  end
end
