# frozen_string_literal: true

module Frontend
  class FleetsController < ApplicationController
    def show
      if fleet.present?
        @title = fleet.name
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render_frontend
    end

    def invite
      @fleet = FleetInviteUrl.find_by(token: params[:token])&.fleet
      if fleet.present?
        @title = I18n.t('title.frontend.fleet_invite', fleet: fleet.name)
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render_frontend
    end

    def stats
      if fleet.present?
        @title = I18n.t('title.frontend.fleet_stats', fleet: fleet.name)
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render_frontend
    end

    def members
      if fleet.present?
        @title = I18n.t('title.frontend.fleet_members', fleet: fleet.name)
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render_frontend
    end

    def settings
      if fleet.present?
        @title = I18n.t('title.frontend.fleet_settings', fleet: fleet.name)
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render_frontend
    end

    private def render_frontend
      respond_to do |format|
        format.html do
          render 'frontend/index', status: :ok
        end
        format.all do
          redirect_to '/404'
        end
      end
    end

    private def fleet
      @fleet ||= Fleet.find_by(slug: (params[:slug] || '').downcase)
    end
  end
end
