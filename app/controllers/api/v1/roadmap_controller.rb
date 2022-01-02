# frozen_string_literal: true

module Api
  module V1
    class RoadmapController < ::Api::BaseController
      before_action :authenticate_user!, only: %i[]

      def index
        authorize! :index, :api_roadmap

        roadmap_query_params['sorts'] = ['rsi_category_id asc', 'name asc']

        @q = RoadmapItem.ransack(roadmap_query_params)

        @roadmap_items = @q.result(distinct: true).sort_by { |item| Gem::Version.new(item.release) }
      end

      def weeks
        authorize! :index, :api_roadmap

        next_roadmap_update = (1.day.from_now).end_of_week(:thursday)
        oldest_roadmap_update = PaperTrail::Version.where(item_type: 'RoadmapItem').order(:created_at).first.created_at
        updates = (oldest_roadmap_update.to_date..next_roadmap_update.to_date).to_a.select { |date| date.wday == 3 }

        @weeks = updates.reverse.each_with_index.map do |update, index|
          {
            value: index,
            query: {
              lastUpdatedAtGteq: I18n.l(update - 7.days),
              lastUpdatedAtLt: I18n.l(update),
            },
            label: "#{I18n.l(update - 7.days)} - #{I18n.l(update - 13.days)}",
          }
        end
      end

      private def roadmap_query_params
        @roadmap_query_params ||= query_params(
          :name_cont, :released_eq, :updated_at_gteq, :updated_at_lteq, :last_updated_at_lteq,
          :last_updated_at_gteq, :active_eq, :last_updated_at_lt, :rsi_release_id_gteq,
          rsi_category_id_in: [], active_in: [], sorts: []
        )
      end
      helper_method :roadmap_query_params
    end
  end
end
