# frozen_string_literal: true

module Api
  module V1
    module Me
      # What the patch we are on changed about the ships the reader owns or
      # wants, most changed first -- its hotfixes included, against the patch
      # before it.
      class PatchChangesController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
          unless: :user_signed_in?,
          only: %i[index]

        skip_verify_authorized only: %i[index]

        LIMIT = 10

        def index
          source = requested_source
          return not_found if params[:environment].present? && source.blank?

          # The build actually served either way: a configured build whose load
          # has not finished has no changes recorded yet.
          source ||= ::ScData::Source.current.served

          @environment = source.environment
          @version = source.version

          vehicles = current_resource_owner.vehicles.where(loaner: false)
          owned_counts = vehicles.where(wanted: false).group(:model_id).count
          wanted_ids = vehicles.where(wanted: true).distinct.pluck(:model_id).to_set

          changes = ModelBuildChange
            .patch_changes(@environment, @version, model_ids: owned_counts.keys | wanted_ids.to_a)
            .sort_by(&:field)
            .group_by(&:model_id)

          models = Model.visible.active
            .where(id: changes.keys)
            .includes(:manufacturer, *Model::IMAGE_ATTACHMENT_PRELOAD)
            .index_by(&:id)

          items = changes.filter_map do |model_id, rows|
            model = models[model_id]
            next if model.blank?

            {model:, owned_count: owned_counts.fetch(model_id, 0), wanted: wanted_ids.include?(model_id), changes: rows}
          end

          @from_version = items.first&.dig(:changes, 0)&.from_version
          @total_count = items.size
          @owned_model_ids = items.filter_map { |item| item[:model].id if item[:owned_count].positive? }
          @items = items.sort_by { |item| [-item[:changes].size, item[:model].name] }.first(LIMIT)
        end

        # A build named outright, for a page that shows live and ptu side by
        # side whichever one the reader has switched to. Only one a reader could
        # switch to: an environment nothing has loaded has no patch to speak of.
        private def requested_source
          return if params[:environment].blank?

          ::ScData::Source.available.find { |source| source.environment == params[:environment].to_s }
        end
      end
    end
  end
end
