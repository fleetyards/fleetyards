# frozen_string_literal: true

module Frontend
  class FleetsController < BaseController
    include LinkPreviewRendering

    def show
      if fleet.present?
        @title = fleet.name
        @og_type = "article"
        @og_image = fleet.logo.attached? ? rails_blob_url(fleet.logo) : nil
      end

      render_frontend
    end

    def invite
      @fleet = FleetInviteUrl.find_by(token: params[:token])&.fleet
      if fleet.present?
        @title = I18n.t("title.frontend.fleet_invite", fleet: fleet.name)
        @og_image = fleet.logo.attached? ? rails_blob_url(fleet.logo) : nil
      end

      render_frontend
    end

    def stats
      if fleet.present?
        @title = I18n.t("title.frontend.fleet_stats", fleet: fleet.name)
        @og_type = "article"
        @og_image = fleet.logo.attached? ? rails_blob_url(fleet.logo) : nil
      end

      render_frontend
    end

    def members
      if fleet.present?
        @title = I18n.t("title.frontend.fleet_members", fleet: fleet.name)
        @og_type = "article"
        @og_image = fleet.logo.attached? ? rails_blob_url(fleet.logo) : nil
      end

      render_frontend
    end

    def event
      render_link_preview(item_fleet&.fleet_events&.find_by(slug: params[:event_slug])) do |fleet_event|
        LinkPreview.for_fleet_event(fleet_event)
      end
    end

    def contract
      render_link_preview(item_fleet&.fleet_contracts&.find_by(slug: params[:contract_slug])) do |fleet_contract|
        LinkPreview.for_fleet_contract(fleet_contract)
      end
    end

    def tour
      render_link_preview(item_fleet&.tours&.find_by(slug: params[:tour_slug])) do |fleet_tour|
        LinkPreview.for_tour(fleet_tour)
      end
    end

    def settings
      if fleet.present?
        @title = I18n.t("title.frontend.fleet_settings", fleet: fleet.name)
        @og_type = "article"
        @og_image = fleet.logo.attached? ? rails_blob_url(fleet.logo) : nil
      end

      render_frontend
    end

    private def fleet
      @fleet ||= Fleet.kept.find_by(slug: (params[:slug] || "").downcase)
    end

    private def item_fleet
      @item_fleet ||= Fleet.kept.find_by(slug: (params[:fleet_slug] || "").downcase)
    end
  end
end
