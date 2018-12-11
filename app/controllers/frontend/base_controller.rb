# frozen_string_literal: true

require 'mini_magick'

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
      @model = model_record
      if @model.present?
        @title = "#{@model.name} - #{@model.manufacturer.name}"
        @description = @model.description
        @og_type = 'article'
        @og_image = @model.store_image.url
      end
      render 'frontend/index'
    end

    def model_images
      @model = model_record
      if @model.present?
        @title = I18n.t('title.frontend.ship_images', model: @model.name)
        @description = I18n.t('meta.ship_images.description', model: @model.name)
        @og_type = 'article'
        @og_image = @model.random_image&.name&.url
      end
      render 'frontend/index'
    end

    def model_videos
      @model = model_record
      if @model.present?
        @title = I18n.t('title.frontend.ship_videos', model: @model.name)
        @description = I18n.t('meta.ship_videos.description', model: @model.name)
        @og_type = 'article'
        @og_image = @model.random_image&.name&.url
      end
      render 'frontend/index'
    end

    def compare_models
      @model_a = Model.find_by(['lower(slug) = :value', { value: (params[:shipA] || '').downcase }])
      @model_b = Model.find_by(['lower(slug) = :value', { value: (params[:shipB] || '').downcase }])
      @title = I18n.t('title.frontend.compare_ships')
      @description = I18n.t('meta.compare_ships.description.default')
      @og_type = 'article'
      if @model_a.present? && @model_b.present?
        @description = I18n.t(
          'meta.compare_ships.description.vs',
          model_a: "#{@model_a.manufacturer.code} #{@model_a.name}",
          model_b: "#{@model_b.manufacturer.code} #{@model_b.name}"
        )
        @og_image = compare_image(@model_a, @model_b)
      end
      render 'frontend/index'
    end

    def starsystem
      @starsystem = Starsystem.find_by(['lower(slug) = :value', { value: (params[:slug] || '').downcase }])
      if @starsystem.present?
        @title = I18n.t('title.frontend.starsystem', starsystem: @starsystem.name)
        # @description = @station.description
        @og_type = 'article'
        @og_image = @starsystem.store_image.url
      end
      render 'frontend/index'
    end

    def station
      @station = Station.find_by(['lower(slug) = :value', { value: (params[:slug] || '').downcase }])
      if @station.present?
        @title = I18n.t('title.frontend.station', station: @station.name, celestial_object: @station.celestial_object.name)
        # @description = @station.description
        @og_type = 'article'
        @og_image = @station.store_image.url
      end
      render 'frontend/index'
    end

    def celestial_object
      @celestial_object = CelestialObject.find_by(['lower(slug) = :value', { value: (params[:slug] || '').downcase }])
      if @celestial_object.present?
        @title = I18n.t('title.frontend.celestial_object', starsystem: @celestial_object.starsystem.name, celestial_object: @celestial_object.name)
        # @description = @station.description
        @og_type = 'article'
        @og_image = @celestial_object.store_image.url
      end
      render 'frontend/index'
    end

    def shop
      @shop = Shop.find_by(['lower(slug) = :value', { value: (params[:slug] || '').downcase }])
      if @shop.present?
        @title =  I18n.t('title.frontend.shop', station: @shop.station.name, shop: @shop.name)
        # @description = @station.description
        @og_type = 'article'
        @og_image = @shop.store_image.url
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
        format.all do
          redirect_to '/404'
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

    private def compare_image(model_a, model_b)
      filename = "#{model_a.slug}-#{model_b.slug}.jpg"
      path = Rails.root.join('public', 'compare', filename)
      return "https://api.fleetyards.net/compare/#{filename}" if File.exist?(path)

      FileUtils.cp(model_a.store_image.file.path, "/tmp/#{model_a.slug}")
      FileUtils.cp(model_a.store_image.file.path, "/tmp/#{model_a.slug}-#{model_b.slug}-base")
      FileUtils.cp(model_b.store_image.file.path, "/tmp/#{model_b.slug}")
      base_image = MiniMagick::Image.new("/tmp/#{model_a.slug}-#{model_b.slug}-base")
      first_image = MiniMagick::Image.new("/tmp/#{model_a.slug}")
      second_image = MiniMagick::Image.new("/tmp/#{model_b.slug}")

      first_image.crop "#{first_image.width / 2}x#{first_image.height}+#{(first_image.width / 2) / 2}+0"
      second_image.crop "#{second_image.width / 2}x#{second_image.height}+#{(second_image.width / 2) / 2}+0"

      composite = base_image.composite(first_image) do |c|
        c.compose 'Over'
        c.geometry '+0+0'
      end
      composite = composite.composite(second_image) do |c|
        c.compose 'Over'
        c.geometry "+#{base_image.width / 2}+0"
      end

      composite.write(path)

      File.chmod(0o644, path)

      "https://api.fleetyards.net/compare/#{filename}"
    end

    private def model_record(slug = params[:slug])
      Model.find_by(['lower(slug) = :value', { value: (slug || '').downcase }])
    end
  end
end
