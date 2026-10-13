# frozen_string_literal: true

module Frontend
  class HangarController < ApplicationController
    def index
      @title = I18n.t("title.frontend.hangar")

      render_frontend
    end

    def public
      @user = User.find_by(["normalized_username = :value", {value: params[:username].downcase}])
      # The preview card shows the flagship, so it is drawn only for a hangar
      # the visitor -- or the link's share token -- may open.
      if @user.present? && public_user_readable?(:show?)
        vehicle = @user.vehicles.public.purchased.includes(:model).order(flagship: :desc, name: :asc).order("models.name asc").first
        @title = I18n.t("title.frontend.public_hangar", user: username(@user.username))
        @og_type = "article"
        @og_image = (vehicle.model.store_image.attached? ? rails_blob_url(vehicle.model.store_image) : nil) if vehicle.present?
        preview_plaque if params[:plaque].present?
      end

      render_frontend
    end

    # A ship's pages are the owner's own, but a link to one still gets passed
    # around: it previews as the ship only where the public hangar shows it.
    def vehicle
      @user = User.find_by(["normalized_username = :value", {value: params[:username].downcase}])
      vehicle = segment_vehicle if @user.present? && public_user_readable?(:show?)

      if vehicle.present?
        @title = I18n.t("title.frontend.public_vehicle", vehicle: public_vehicle_name(vehicle), user: username(@user.username))
        @description = vehicle_description(vehicle)
        @og_type = "article"
        @og_image = vehicle_picture_url(vehicle)
        @twitter_card = "summary_large_image" if @og_image.present?
      else
        @title = I18n.t("title.frontend.hangar")
      end

      render_frontend
    end

    def wishlist
      @user = User.find_by(["normalized_username = :value", {value: params[:username].downcase}])
      if @user.present? && public_user_readable?(:wishlist?)
        vehicle = @user.vehicles.wanted.includes(:model).order(flagship: :desc, name: :asc).order("models.name asc").first
        @title = I18n.t("title.frontend.public_wishlist", user: username(@user.username))
        @og_type = "article"
        @og_image = (vehicle.model.store_image.attached? ? rails_blob_url(vehicle.model.store_image) : nil) if vehicle.present?
      end

      render_frontend
    end

    # A shared plaque previews as itself: the owner's rendering of it, the ship's
    # name and its dedication. Only a ship the public hangar shows; until the
    # plaque has been drawn, the ship's own picture stands in.
    private def preview_plaque
      return unless Flipper.enabled?(:vehicle_overview, @user)

      vehicle = @user.vehicles.public.purchased.find_by(id: params[:plaque])
      return if vehicle&.dedication.blank?

      @title = I18n.t("title.frontend.public_plaque", vehicle: public_vehicle_name(vehicle))
      @description = vehicle.dedication
      @og_image = vehicle.plaque_image.attached? ? rails_blob_url(vehicle.plaque_image) : vehicle_picture_url(vehicle)
      @twitter_card = "summary_large_image" if @og_image.present?
    end

    # The address leads with the ship's serial or its id; the name after it is
    # only there to read, and is never looked up.
    private def segment_vehicle
      scope = @user.vehicles.public.purchased.includes(:model)
      segment = params[:segment].to_s

      if (id = segment[/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i])
        scope.find_by(id: id.downcase)
      elsif (serial = segment[/\A[0-9a-z]{2}-[0-9a-z]{4}-[0-9a-z]{2}/i])
        scope.find_by(serial: serial.upcase)
      end
    end

    private def vehicle_description(vehicle)
      text = vehicle.dedication.presence || vehicle.model.description
      return if text.blank?

      helpers.truncate(helpers.strip_tags(text).squish, length: 200)
    end

    # The picture the public hangar shows for the ship: the owner's own, else the
    # one they picked from the model's gallery, else the model's.
    private def vehicle_picture_url(vehicle)
      return rails_blob_url(vehicle.image) if vehicle.image.attached?
      return rails_blob_url(vehicle.model_image.file) if vehicle.model_image&.enabled? && vehicle.model_image.file.attached?

      rails_blob_url(vehicle.model.store_image) if vehicle.model.store_image.attached?
    end

    # The name the public hangar shows: the owner's own only where they show it.
    private def public_vehicle_name(vehicle)
      return vehicle.name if vehicle.name_visible? && vehicle.name.present?

      vehicle.model.name
    end

    private def public_user_readable?(rule)
      ::Public::UserPolicy.new(@user, user: current_user, share_token: params[:share].presence).apply(rule)
    end

    private def render_frontend
      respond_to do |format|
        format.html do
          render "frontend/index", status: :ok
        end
        format.all do
          redirect_to "/404"
        end
      end
    end

    private def username(name)
      return name if name.ends_with?("s") || name.ends_with?("x") || name.ends_with?("z")

      "#{name}'s"
    end
  end
end
