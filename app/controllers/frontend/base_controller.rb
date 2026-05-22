# frozen_string_literal: true

require "image_processing/mini_magick"

module Frontend
  class BaseController < ApplicationController
    before_action :check_short_domain
    before_action :add_flash_messages_to_prefetch
    before_action :add_features_to_prefetch

    include PrefetchHelper

    def index
      route = request.fullpath.split("?").first.sub(%r{^/}, "").tr("/", "_")
      route = "home" if route.blank?

      @title = I18n.t("title.frontend.#{route}") if I18n.exists?("title.frontend.#{route}")

      render_frontend
    end

    def confirm
      @title = I18n.t("title.frontend.confirm")

      render_frontend
    end

    def password
      @title = I18n.t("title.frontend.password_change")

      render_frontend
    end

    def model
      @model = model_record.includes(model_hardpoints: [:component]).first
      return if redirect_to_canonical_slug(@model)

      if @model.present?
        @title = "#{@model.name} - #{@model.manufacturer.name}"
        @description = @model.description
        @og_type = "article"
        @og_image = @model.store_image.attached? ? rails_blob_url(@model.store_image) : nil
        add_to_prefetch(:model, @model.to_json)
      end

      render_frontend
    end

    def model_images
      @model = model_record.first
      return if redirect_to_canonical_slug(@model)

      if @model.present?
        @title = I18n.t("title.frontend.ship_images", model: @model.name)
        @description = I18n.t("meta.ship_images.description", model: @model.name)
        @og_type = "article"
        random_img = @model.random_image
        @og_image = random_img&.file&.attached? ? rails_blob_url(random_img.file) : nil
      end

      render_frontend
    end

    def model_videos
      @model = model_record.first
      return if redirect_to_canonical_slug(@model)

      if @model.present?
        @title = I18n.t("title.frontend.ship_videos", model: @model.name)
        @description = I18n.t("meta.ship_videos.description", model: @model.name)
        @og_type = "article"
        random_img = @model.random_image
        @og_image = random_img&.file&.attached? ? rails_blob_url(random_img.file) : nil
      end

      render_frontend
    end

    def compare_models
      slugs = (compare_params[:models] || []).map(&:downcase)
      @models = Model.where(slug: slugs).or(Model.where(legacy_slug: slugs)).order(name: :asc).limit(8).all
      @title = I18n.t("title.frontend.compare_ships")
      @description = I18n.t("meta.compare_ships.description.default")
      @og_type = "article"
      if @models.present?
        @description = I18n.t(
          "meta.compare_ships.description.vs",
          models: @models.map(&:name).join(" vs. ")
        )
        @og_image = @models.first.store_image.attached? ? rails_blob_url(@models.first.store_image) : nil
        # compare_image(@models) TODO: needs to be updated for AWS images
      end

      render_frontend
    end

    def manifest
      respond_to do |format|
        format.json do
          render "frontend/manifest", status: :ok, layout: false
        end
        format.all do
          redirect_to "/404"
        end
      end
    end

    private def add_flash_messages_to_prefetch
      messages = []

      if flash[:alert].present?
        messages << {
          type: "alert",
          text: flash[:alert]
        }
      end
      if flash[:error].present?
        messages << {
          type: "alert",
          text: flash[:error]
        }
      end
      if flash[:warning].present?
        messages << {
          type: "warning",
          text: flash[:warning]
        }
      end
      if flash[:notice].present?
        messages << {
          type: "info",
          text: flash[:notice]
        }
      end
      if flash[:success].present?
        messages << {
          type: "success",
          text: flash[:success]
        }
      end

      return if messages.blank?

      add_to_prefetch(:notifications, messages.to_json)
    end

    def add_features_to_prefetch
      user_features = Flipper.features.filter_map do |feature|
        Flipper.enabled?(feature.name, current_user) ? feature.to_s : nil
      end
      fleet_features = Flipper.features.filter_map do |feature|
        Flipper.enabled?(feature.name, current_user&.fleets.to_a) ? feature.to_s : nil
      end

      features = (user_features + fleet_features).uniq

      return if features.blank?

      add_to_prefetch(:features, features.to_json)
    end

    private def render_frontend
      respond_to do |format|
        format.html do
          response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
          response.headers["Pragma"] = "no-cache"
          response.headers["Expires"] = "0"
          render "frontend/index", status: :ok
        end
        format.all do
          redirect_to "/404"
        end
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    private def compare_image(models)
      return (models.first.store_image.attached? ? rails_blob_url(models.first.store_image) : nil) if models.size == 1
      return if models.blank?

      filename_base = models.map(&:slug).join("-")
      filename = "#{filename_base}.jpg"
      path = Rails.public_path.join("compare", filename)
      return "https://fleetyards.net/compare/#{filename}" if File.exist?(path)

      models.each_with_index do |model, index|
        next unless model.store_image.attached?

        tempfile = Tempfile.new([model.slug, ".jpg"])
        tempfile.binmode
        model.store_image.download { |chunk| tempfile.write(chunk) }
        tempfile.rewind
        image = MiniMagick::Image.new(tempfile.path)
        image.write(Rails.root.join("tmp", model.slug))
        image.write(Rails.root.join("tmp", "#{filename_base}-base")) if index.zero?
        tempfile.close!
      end

      base_image = MiniMagick::Image.new(Rails.root.join("tmp", "#{filename_base}-base"))
      base_image_pipeline = ImageProcessing::MiniMagick.source(Rails.root.join("tmp", "#{filename_base}-base"))

      images = models.map do |model|
        image = MiniMagick::Image.new(Rails.root.join("tmp", model.slug))
        ImageProcessing::MiniMagick
          .source(Rails.root.join("tmp", model.slug))
          .resize_to_fill!(image.width / models.size, image.height)
      end

      composite = base_image_pipeline.composite(images.first)

      images.each_with_index do |image, index|
        next if index.zero?

        composite = composite.composite(image, offset: [(base_image.width / models.size) * index, 0])
      end

      composite.call(destination: path)

      File.chmod(0o644, path)

      FileUtils.rm(Rails.root.join("tmp", "#{filename_base}-base"))
      models.each do |model|
        FileUtils.rm(Rails.root.join("tmp", model.slug))
      end

      "https://fleetyards.net/compare/#{filename}"
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    private def compare_params
      @compare_params ||= params.permit(models: [])
    end

    private def model_record(slug = params[:slug])
      slug = (slug || "").downcase
      Model.where(slug:).or(Model.where(legacy_slug: slug))
    end

    private def redirect_to_canonical_slug(model)
      return false if model.blank?
      return false if model.slug == params[:slug]&.downcase

      redirect_to url_for(slug: model.slug), status: :moved_permanently
      true
    end

    private def check_short_domain
      return if Rails.configuration.app.short_domain.blank? || request.host != Rails.configuration.app.short_domain

      redirect_to frontend_root_url, allow_other_host: true
    end
  end
end
