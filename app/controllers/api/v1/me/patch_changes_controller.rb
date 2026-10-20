# frozen_string_literal: true

module Api
  module V1
    module Me
      # What the build we are on changed about the ships the reader owns or
      # wants, most changed first.
      class PatchChangesController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
          unless: :user_signed_in?,
          only: %i[index]

        skip_verify_authorized only: %i[index]

        LIMIT = 10

        def index
          @environment = ::ScData::Source.environment
          @version = ::ScData::Source.version

          vehicles = current_resource_owner.vehicles.where(loaner: false)
          owned_counts = vehicles.where(wanted: false).group(:model_id).count
          wanted_ids = vehicles.where(wanted: true).distinct.pluck(:model_id).to_set

          changes = ModelBuildChange
            .for_build(@environment, @version)
            .where(model_id: owned_counts.keys | wanted_ids.to_a)
            .order(:field)
            .group_by(&:model_id)

          models = Model.visible.active
            .where(id: changes.keys)
            .includes(:manufacturer, store_image_attachment: :blob)
            .index_by(&:id)

          items = changes.filter_map do |model_id, rows|
            model = models[model_id]
            next if model.blank?

            {model:, owned_count: owned_counts.fetch(model_id, 0), wanted: wanted_ids.include?(model_id), changes: rows}
          end

          @from_version = items.first&.dig(:changes, 0)&.from_version
          @total_count = items.size
          @items = items.sort_by { |item| [-item[:changes].size, item[:model].name] }.first(LIMIT)
        end
      end
    end
  end
end
