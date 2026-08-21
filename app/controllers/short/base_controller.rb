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

    def model_compare_share
      record = CompareImage.find_by(short_code: params[:short_code])
      if record.blank? || record.share_key.blank?
        redirect_to frontend_compare_url, allow_other_host: true
        return
      end

      slugs = canonical_share_slugs(record.share_key)
      if slugs.empty?
        redirect_to frontend_compare_url, allow_other_host: true
        return
      end

      redirect_to frontend_compare_url(models: slugs), allow_other_host: true
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

    private def canonical_share_slugs(share_key)
      raw_slugs = share_key.split(CompareImage::SHARE_KEY_SEPARATOR)
      return [] if raw_slugs.empty?

      Model.where(slug: raw_slugs).or(Model.where(legacy_slug: raw_slugs))
        .pluck(:slug).uniq.sort
    end
  end
end
