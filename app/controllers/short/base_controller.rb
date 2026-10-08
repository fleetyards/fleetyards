# frozen_string_literal: true

module Short
  class BaseController < ApplicationController
    def hangar
      redirect_to with_query(frontend_public_hangar_url(username: params[:username])), allow_other_host: true
    end

    def wishlist
      redirect_to with_query(frontend_public_wishlist_url(username: params[:username])), allow_other_host: true
    end

    def hangar_stats
      redirect_to frontend_public_hangar_stats_url(username: params[:username], share: params[:share].presence), allow_other_host: true
    end

    def hangar_fleetchart
      redirect_to with_query(frontend_public_hangar_fleetchart_url(username: params[:username])), allow_other_host: true
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

    def fleet_ships
      fleet = Fleet.kept.find_by(normalized_fid: params[:fleet_fid].to_s.downcase)
      if fleet
        redirect_to with_query(frontend_fleet_ships_url(slug: fleet.slug)), allow_other_host: true
      else
        redirect_to "/404", allow_other_host: true
      end
    end

    def fleet_event
      fleet = Fleet.kept.find_by(normalized_fid: params[:fleet_fid].to_s.downcase)
      event = fleet&.fleet_events&.find_by(slug: params[:event_slug])
      if event
        redirect_to with_query(frontend_fleet_event_url(fleet_slug: fleet.slug, event_slug: event.slug)), allow_other_host: true
      else
        redirect_to "/404", allow_other_host: true
      end
    end

    # The raw string, not a rebuilt one: to_query turns a repeated filter key
    # into `key[]`, which the frontend router reads as a different key.
    private def with_query(url)
      return url if request.query_string.blank?

      "#{url}?#{request.query_string}"
    end

    private def canonical_share_slugs(share_key)
      raw_slugs = share_key.split(CompareImage::SHARE_KEY_SEPARATOR)
      return [] if raw_slugs.empty?

      Model.where(slug: raw_slugs).or(Model.where(legacy_slug: raw_slugs))
        .pluck(:slug).uniq.sort
    end
  end
end
