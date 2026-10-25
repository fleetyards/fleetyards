# frozen_string_literal: true

module Frontend
  class HangarController < ApplicationController
    include OgImageMeta

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
        @title = I18n.t("title.frontend.public_hangar", user: username(@user.shown_name))
        @og_type = "article"
        use_og_image(vehicle.model.display_image, alt: vehicle.model.name) if vehicle.present?
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
        @title = I18n.t("title.frontend.public_vehicle", vehicle: public_vehicle_name(vehicle), user: username(@user.shown_name))
        @description = vehicle_description(vehicle)
        @og_type = "article"
        use_og_image(vehicle_picture(vehicle), alt: public_vehicle_name(vehicle))
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
        @title = I18n.t("title.frontend.public_wishlist", user: username(@user.shown_name))
        @og_type = "article"
        use_og_image(vehicle.model.display_image, alt: vehicle.model.name) if vehicle.present?
      end

      render_frontend
    end

    # A shared plaque previews as itself: the owner's rendering of it, the ship's
    # name and its dedication. Only a ship the public hangar shows; until the
    # plaque has been drawn, the ship's own picture stands in.
    private def preview_plaque
      return unless Flipper.enabled?(:vehicle_overview, @user)

      vehicle = @user.vehicles.public.purchased.includes(:model).at_address(params[:plaque]).first
      return if vehicle&.dedication.blank?

      @title = I18n.t("title.frontend.public_plaque", vehicle: public_vehicle_name(vehicle))
      @description = vehicle.dedication
      # A ship without a picture keeps the hangar's, rather than none at all.
      if vehicle.plaque_image.attached?
        use_og_image(vehicle.plaque_image, alt: @title)
      else
        use_og_image(vehicle_picture(vehicle), alt: public_vehicle_name(vehicle))
      end
      @twitter_card = "summary_large_image" if @og_image.present?
    end

    private def segment_vehicle
      @user.vehicles.public.purchased.includes(:model).at_address(params[:segment]).first
    end

    private def vehicle_description(vehicle)
      text = vehicle.dedication.presence || vehicle.model.description
      return if text.blank?

      helpers.truncate(helpers.strip_tags(text).squish, length: 200)
    end

    # The picture the public hangar shows for the ship: the owner's own or picked
    # one, else the model's.
    private def vehicle_picture(vehicle)
      return vehicle.display_image if vehicle.display_image.present?

      vehicle.model.display_image
    end

    # The name the public hangar shows: the owner's own, and its serial, only
    # where they show them -- the public payload hides both together.
    private def public_vehicle_name(vehicle)
      return vehicle.model.name unless vehicle.name_visible?

      name = vehicle.name.presence || vehicle.model.name
      vehicle.serial.present? ? "#{name} (#{vehicle.serial})" : name
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
      return name if name.downcase.end_with?("s", "x", "z")

      "#{name}'s"
    end
  end
end
