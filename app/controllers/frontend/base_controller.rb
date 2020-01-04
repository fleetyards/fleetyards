# frozen_string_literal: true

require 'image_processing/mini_magick'

module Frontend
  class BaseController < ApplicationController
    include PrefetchHelper

    def index
      route = request.fullpath.split('?').first.sub(%r{^\/}, '').tr('/', '_')
      route = 'home' if route.blank?

      @title = I18n.t("title.frontend.#{route}")

      render 'frontend/index'
    end

    def confirm
      @title = I18n.t('title.frontend.confirm')
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

    def model
      @model = model_record
      if @model.present?
        @title = "#{@model.name} - #{@model.manufacturer.name}"
        @description = @model.description
        @og_type = 'article'
        @og_image = @model.store_image.url
        add_to_prefetch(:model, @model.to_json)
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
      @models = Model.where(slug: (compare_params[:models] || []).map(&:downcase)).order(name: :asc).limit(8).all
      @title = I18n.t('title.frontend.compare_ships')
      @description = I18n.t('meta.compare_ships.description.default')
      @og_type = 'article'
      if @models.present?
        @description = I18n.t(
          'meta.compare_ships.description.vs',
          models: @models.map(&:name).join(' vs. ')
        )
        @og_image = compare_image(@models)
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

    def station_images
      @station = Station.find_by(['lower(slug) = :value', { value: (params[:slug] || '').downcase }])
      if @station.present?
        @title = I18n.t('title.frontend.station_images', station: @station.name, celestial_object: @station.celestial_object.name)
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

    private def compare_image(models)
      return models.first.store_image.url if models.size == 1
      return if models.blank?

      filename_base = models.map(&:slug).join('-')
      filename = "#{filename_base}.jpg"
      path = Rails.root.join('public', 'compare', filename)
      return "https://fleetyards.net/compare/#{filename}" if File.exist?(path)

      models.each_with_index do |model, index|
        image = MiniMagick::Image.open(model.store_image.to_s)
        image.write(Rails.root.join('tmp', model.slug))
        image.write(Rails.root.join('tmp', "#{filename_base}-base")) if index.zero?
      end

      base_image = MiniMagick::Image.new(Rails.root.join('tmp', "#{filename_base}-base"))
      base_image_pipeline = ImageProcessing::MiniMagick.source(Rails.root.join('tmp', "#{filename_base}-base"))

      images = models.map do |model|
        image = MiniMagick::Image.new(Rails.root.join('tmp', model.slug))
        ImageProcessing::MiniMagick
          .source(Rails.root.join('tmp', model.slug))
          .resize_to_fill!(image.width / models.size, image.height)
      end

      composite = base_image_pipeline.composite(images.first)

      images.each_with_index do |image, index|
        next if index.zero?

        composite = composite.composite(image, offset: [(base_image.width / models.size) * index, 0])
      end

      composite.call(destination: path)

      File.chmod(0o644, path)

      FileUtils.rm(Rails.root.join('tmp', "#{filename_base}-base"))
      models.each do |model|
        FileUtils.rm(Rails.root.join('tmp', model.slug))
      end

      "https://fleetyards.net/compare/#{filename}"
    end

    private def compare_params
      @compare_params ||= params.permit(models: [])
    end

    private def model_record(slug = params[:slug])
      Model.find_by(['lower(slug) = :value', { value: (slug || '').downcase }])
    end
  end
end
