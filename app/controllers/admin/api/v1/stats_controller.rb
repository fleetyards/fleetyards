# frozen_string_literal: true

module Admin
  module Api
    module V1
      class StatsController < ::Admin::Api::BaseController
        include TrackingStatsConcern

        # Ahoy writes the path a `$view` event was recorded on into its
        # `properties` document; there is no column for it.
        VIEWED_PAGE = Arel.sql("ahoy_events.properties->>'page'")

        # The dashboard refetches on every window focus, and these are counts
        # over whole tables. None of them moves enough in five minutes to be
        # worth counting again; `online_count` is deliberately not among them.
        TOTALS_TTL = 5.minutes

        def quick_stats
          authorize! with: ::Admin::StatsPolicy

          totals = Rails.cache.fetch("admin/stats/quick_stats", expires_in: TOTALS_TTL) do
            {
              ships_count_year: Model.year(Time.current.year).count,
              ships_count_total: Model.count,
              users_count_total: User.count,
              fleets_count_total: Fleet.count
            }
          end

          @quick_stats = {online_count:}.merge(totals)
        end

        def most_viewed_pages
          authorize! with: ::Admin::StatsPolicy

          # Grouped in the database rather than in Ruby. Ten rows come back; the
          # month behind them is tens of thousands of events, and each one was
          # instantiated with its whole `properties` document to be counted.
          most_viewed_pages = Ahoy::Event.one_month.where(name: "$view")
            .group(VIEWED_PAGE)
            .order(Arel.sql("COUNT(*) DESC"))
            .limit(10)
            .count
            .map do |page, count|
              {
                label: page,
                count:,
                tooltip: page
              }
            end

          render json: most_viewed_pages.to_json
        end

        def visits_per_day
          authorize! with: ::Admin::StatsPolicy

          # Read from the daily rollup `MetricsJob` writes, rather than
          # aggregating a month of `ahoy_visits` on every request.
          #
          # The window is whole days now. The query this replaces began at a
          # timestamp one month back, so its leftmost bar covered only part of
          # that day and always read low -- 1,846 against the day's real 4,848
          # on the database I checked.
          visits_per_day = Rollup.where(time: 1.month.ago.to_date...Time.zone.today)
            .series("Visits", interval: :day)
            .map do |started_at, count|
            {
              label: I18n.l(started_at.to_date, format: :day_month_short),
              count: count.to_i,
              tooltip: I18n.l(started_at.to_date, format: :day_month)
            }
          end

          render json: visits_per_day.to_json
        end

        def visits_per_month
          authorize! with: ::Admin::StatsPolicy

          visits_per_month = Rollup.where("time > ?", 1.year.ago).series("Visits", interval: :month).map do |started_at, count|
            {
              label: I18n.l(started_at.to_date, format: :month_year_short),
              count:,
              tooltip: I18n.l(started_at.to_date, format: :month_year)
            }
          end

          render json: visits_per_month.to_json
        end

        def registrations_per_month
          authorize! with: ::Admin::StatsPolicy

          registrations_per_month = Rollup.where("time > ?", 1.year.ago).series("Registrations", interval: :month).map do |created_at, count|
            {
              label: I18n.l(created_at.to_date, format: :month_year_short),
              count:,
              tooltip: I18n.l(created_at.to_date, format: :month_year)
            }
          end

          render json: registrations_per_month.to_json
        end
      end
    end
  end
end
