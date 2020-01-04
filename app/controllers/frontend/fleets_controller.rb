# frozen_string_literal: true

module Frontend
  class FleetsController < ApplicationController
    def show
      if fleet.present?
        @title = fleet.name
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render 'frontend/index'
    end

    def members
      if fleet.present?
        @title = I18n.t('title.frontend.fleet_members', fleet: fleet.name)
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render 'frontend/index'
    end

    def settings
      if fleet.present?
        @title = I18n.t('title.frontend.fleet_settings', fleet: fleet.name)
        @og_type = 'article'
        @og_image = fleet.logo.url if fleet.logo.present?
      end

      render 'frontend/index'
    end

    private def fleet
      @fleet ||= Fleet.find_by(slug: (params[:slug] || '').downcase)
    end
  end
end
