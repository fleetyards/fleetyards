# frozen_string_literal: true

module Admin
  module Api
    module V1
      class DestroyedFleetsController < ::Admin::Api::BaseController
        SOURCES = %w[discarded purged].freeze

        def index
          authorize! with: ::Admin::FleetPolicy

          if source == "purged"
            @purged_fleets = purged_fleets
          else
            @discarded_fleets = discarded_fleets
          end
        end

        def restore
          authorize! with: ::Admin::FleetPolicy

          if source == "purged"
            @fleet = ::Fleets::PurgedFleetRestorer.new(params[:id]).call
          else
            @fleet = Fleet.discarded.find(params[:id])
            @fleet.undiscard
          end

          render "show"
        rescue ::Fleets::PurgedFleetRestorer::FleetStillExists
          render json: {
            code: "destroyed_fleets.fleet_still_exists",
            message: I18n.t("messages.destroyed_fleets.fleet_still_exists")
          }, status: :unprocessable_entity
        rescue ::Fleets::PurgedFleetRestorer::NothingToRestore, ActiveRecord::RecordNotFound
          not_found(I18n.t("messages.record_not_found.fleet"))
        end

        private def source
          @source ||= SOURCES.include?(params[:source]) ? params[:source] : "discarded"
        end

        private def search_term
          params.dig(:q, :name_or_fid_cont).presence
        end

        private def discarded_fleets
          scope = Fleet.discarded
          if search_term
            scope = scope.where("fleets.name ILIKE :q OR fleets.fid ILIKE :q", q: "%#{search_term}%")
          end
          scope.order(discarded_at: :desc)
            .page(params[:page])
            .per(per_page(Fleet))
        end

        # PaperTrail destroy versions for fleets that no longer exist in the table.
        private def purged_fleets
          scope = PaperTrail::Version
            .where(item_type: "Fleet", event: "destroy")
            .where.not(item_id: Fleet.unscoped.select(:id))
          if search_term
            scope = scope.where("object ->> 'name' ILIKE :q OR object ->> 'fid' ILIKE :q", q: "%#{search_term}%")
          end
          scope.order(created_at: :desc)
            .page(params[:page])
            .per(per_page(Fleet))
        end
      end
    end
  end
end
