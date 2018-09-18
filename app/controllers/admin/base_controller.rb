# frozen_string_literal: true

module Admin
  class BaseController < ::Admin::ApplicationController
    layout 'admin/application'

    def index
      authorize! :show, :admin
      @active_nav = 'admin'
      blacklist = User.where(tracking: false).pluck(:id)
      @latest_users = User.unscoped.order(created_at: :desc).limit(8)
      @latest_models = Model.order(updated_at: :desc, name: :asc).limit(10)
      @latest_manufacturers = Manufacturer.unscoped.order(updated_at: :desc).limit(10)
      @latest_components = Component.unscoped.order(updated_at: :desc).limit(10)
      @worker_running = worker_running?
      @visits_per_day = transform_chart_for_day(Ahoy::Visit.without_users(blacklist).one_month.group_by_day(:started_at).count)
      @visits_per_month = transform_chart_for_month(Ahoy::Visit.without_users(blacklist).one_year.group_by_month(:started_at).count)
      @registrations_per_month = transform_chart_for_month(
        User.where('created_at > ?', Time.zone.now - 1.year)
            .group_by_month(:created_at)
            .count
      )
    end

    def quick_stats
      authorize! :show, :admin
      respond_to do |format|
        format.js do
          render json: {
            online_count: Ahoy::Event.select(:visit_id).distinct.where('time > ?', 15.minutes.ago).count,
            ships_count_year: Model.year(Time.current.year).count,
            ships_count_total: Model.count,
            users_count_total: User.count
          }
        end
        format.html do
          redirect_to root_path
        end
      end
    end

    private def transform_chart_for_month(data)
      data.map do |day, count|
        { I18n.l(day.to_date, format: :month_year_short) => count }
      end.reduce(:merge)
    end

    private def transform_chart_for_day(data)
      data.map do |day, count|
        { I18n.l(day.to_date, format: :short) => count }
      end.reduce(:merge)
    end
  end
end
