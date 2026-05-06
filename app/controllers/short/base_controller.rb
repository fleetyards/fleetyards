# frozen_string_literal: true

module Short
  class BaseController < ApplicationController
    def hangar
      redirect_to frontend_public_hangar_url(username: params[:username]), allow_other_host: true
    end

    def wishlist
      redirect_to frontend_public_wishlist_url(username: params[:username]), allow_other_host: true
    end

    def fleet_invite
      redirect_to frontend_fleet_invite_url(token: params[:token]), allow_other_host: true
    end

    def model_compare
      redirect_to frontend_compare_ships_url(params: request.query_parameters), allow_other_host: true
    end

    def fleet_event
      fleet = Fleet.find_by("LOWER(fid) = ?", params[:fleet_fid].to_s.downcase)
      event = fleet&.fleet_events&.find_by(slug: params[:event_slug])
      if event
        redirect_to frontend_fleet_event_url(fleet_slug: fleet.slug, event_slug: event.slug), allow_other_host: true
      else
        redirect_to "/404", allow_other_host: true
      end
    end
  end
end
