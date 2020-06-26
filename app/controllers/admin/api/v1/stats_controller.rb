# frozen_string_literal: true

module Admin
  module Api
    module V1
      class StatsController < ::Admin::Api::BaseController
        def quick_stats
          authorize! :stats, :admin

          quick_stats = {
            online_count: online_count,
            ships_count_year: Model.year(Time.current.year).count,
            ships_count_total: Model.count,
            users_count_total: User.count,
            fleets_count_total: Fleet.count
          }

          render json: quick_stats.to_json
        end

        def most_viewed_pages
          authorize! :stats, :admin

          most_viewed_pages = Ahoy::Event.where(name: '$view').to_a.group_by do |event|
            event.properties['page']
          end.map do |page, views|
            {
              label: page,
              count: views.size,
              tooltip: page
            }
          end.sort_by { |item| item[:count] }.reverse.take(10)

          render json: most_viewed_pages.to_json
        end

        def visits_per_day
          authorize! :stats, :admin

          visits_per_day = Ahoy::Visit.without_users(tracking_blocklist).one_month
                                      .group_by_day(:started_at).count
                                      .map do |created_at, count|
                                        {
                                          label: I18n.l(created_at.to_date, format: :day_month_short),
                                          count: count,
                                          tooltip: I18n.l(created_at.to_date, format: :day_month)
                                        }
                                      end

          render json: visits_per_day.to_json
        end

        def visits_per_month
          authorize! :stats, :admin

          visits_per_month = Ahoy::Visit.without_users(tracking_blocklist).one_year
                                        .group_by_month(:started_at).count
                                        .map do |started_at, count|
                                          {
                                            label: I18n.l(started_at.to_date, format: :month_year_short),
                                            count: count,
                                            tooltip: I18n.l(started_at.to_date, format: :month_year)
                                          }
                                        end

          render json: visits_per_month.to_json
        end

        def registrations_per_month
          authorize! :stats, :admin

          registrations_per_month = User.where('created_at > ?', Time.zone.now - 1.year)
                                        .group_by_month(:created_at)
                                        .count
                                        .map do |created_at, count|
                                          {
                                            label: I18n.l(created_at.to_date, format: :month_year_short),
                                            count: count,
                                            tooltip: I18n.l(created_at.to_date, format: :month_year)
                                          }
                                        end

          render json: registrations_per_month.to_json
        end

        private def online_count
          Ahoy::Event.without_users(tracking_blocklist)
                     .select(:visit_id).distinct
                     .where('time > ?', 15.minutes.ago).count
        end
        helper_method :online_count

        private def tracking_blocklist
          @tracking_blocklist ||= User.where(tracking: false).pluck(:id)
        end
      end
    end
  end
end
