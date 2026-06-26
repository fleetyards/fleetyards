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
            @destroyed_by = whodunnit_labels(@purged_fleets.map(&:whodunnit))
          else
            @discarded_fleets = discarded_fleets
            @discarded_by = discard_whodunnit(@discarded_fleets.map(&:id))
            @destroyed_by = whodunnit_labels(@discarded_by.values)
          end
        end

        def restore
          authorize! with: ::Admin::FleetPolicy

          @fleet = (source == "purged") ? restore_purged : restore_discarded

          render "show"
        rescue ::Fleets::PurgedFleetRestorer::FleetStillExists
          render_restore_error("destroyed_fleets.fleet_still_exists", "messages.destroyed_fleets.fleet_still_exists")
        rescue ::Fleets::PurgedFleetRestorer::FidTaken, ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
          render_restore_error("destroyed_fleets.fid_taken", "messages.destroyed_fleets.fid_taken")
        rescue ::Fleets::PurgedFleetRestorer::NothingToRestore, ActiveRecord::RecordNotFound
          not_found(I18n.t("messages.record_not_found.fleet"))
        end

        private def restore_discarded
          fleet = Fleet.discarded.find(params[:id])
          fleet.undiscard!
          fleet
        end

        private def restore_purged
          ::Fleets::PurgedFleetRestorer.new(params[:id]).call
        end

        private def render_restore_error(code, message_key)
          render json: {code:, message: I18n.t(message_key)}, status: :unprocessable_entity
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

        # PaperTrail destroy versions for fleets that no longer exist in the
        # table, de-duplicated to the latest destroy event per fleet.
        private def purged_fleets
          scope = PaperTrail::Version
            .where(item_type: "Fleet", event: "destroy")
            .where.not(item_id: Fleet.unscoped.select(:id))
          if search_term
            scope = scope.where("object ->> 'name' ILIKE :q OR object ->> 'fid' ILIKE :q", q: "%#{search_term}%")
          end

          latest = scope
            .select("DISTINCT ON (versions.item_id) versions.*")
            .order(Arel.sql("versions.item_id, versions.created_at DESC"))

          PaperTrail::Version.from(latest, :versions)
            .order(created_at: :desc)
            .page(params[:page])
            .per(per_page(Fleet))
        end

        # fleet_id => whodunnit of the most recent version (the discard).
        private def discard_whodunnit(fleet_ids)
          return {} if fleet_ids.empty?

          PaperTrail::Version
            .where(item_type: "Fleet", item_id: fleet_ids)
            .select("DISTINCT ON (item_id) item_id, whodunnit")
            .order(Arel.sql("item_id, created_at DESC"))
            .each_with_object({}) { |version, map| map[version.item_id] = version.whodunnit }
        end

        # Resolves whodunnit ids (User or AdminUser) to display names in one
        # query per table, so the "Destroyed By" column shows a username.
        private def whodunnit_labels(ids)
          ids = ids.compact.uniq
          return {} if ids.empty?

          labels = User.where(id: ids).pluck(:id, :username).to_h
          AdminUser.where(id: ids - labels.keys).pluck(:id, :username).each { |id, name| labels[id] = name }
          labels
        end
      end
    end
  end
end
