# frozen_string_literal: true

module Admin
  class BaseController < ::Admin::ApplicationController
    layout 'admin/application'

    def index
      authorize! :show, :admin
      @active_nav = 'admin'
      @worker_running = worker_running?
      @visits_per_day = Ahoy::Visit.group_by_day(:started_at).count.map do |day, count|
        { I18n.l(day.to_date, format: :short) => count }
      end.reduce(:merge)
      @visits_per_month = Ahoy::Visit.group_by_month(:started_at).count.map do |day, count|
        { I18n.l(day.to_date, format: :month_year_short) => count }
      end.reduce(:merge)
      @registrations_per_month = User.where('created_at > ?', Time.zone.now - 1.year)
                                     .group_by_month(:created_at)
                                     .count
                                     .map do |day, count|
        { I18n.l(day.to_date, format: :month_year_short) => count }
      end.reduce(:merge)
    end

    def quick_stats
      authorize! :show, :admin
      respond_to do |format|
        format.js do
          render json: {
            online_count: Ahoy::Event.select(:visit_id).distinct.where('time > ?', 15.minutes.ago).count,
            ships_count_year: Model.year(Time.current.year).count,
            ships_count_total: Model.count
          }
        end
        format.html do
          redirect_to root_path
        end
      end
    end
  end
end
