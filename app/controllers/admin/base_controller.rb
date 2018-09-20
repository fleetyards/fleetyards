# frozen_string_literal: true

module Admin
  class BaseController < ::Admin::ApplicationController
    layout 'admin/application'

    def index
      authorize! :show, :admin
      @active_nav = 'admin'
      @latest_users = User.unscoped.order(created_at: :desc).limit(8)
      @latest_models = Model.order(updated_at: :desc, name: :asc).limit(8)
      @latest_manufacturers = Manufacturer.unscoped.order(updated_at: :desc).limit(8)
      @latest_components = Component.unscoped.order(updated_at: :desc).limit(8)
      @worker_running = worker_running?
    end

    def quick_stats
      authorize! :show, :admin
      respond_to do |format|
        format.js do
          render json: {
            online_count: online_count,
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

    private def visits_per_day
      Ahoy::Visit.without_users(tracking_blacklist).one_month
                 .group_by_day(:started_at).count
                 .map do |created_at, count|
                   {
                     label: I18n.l(created_at.to_date, format: :day_month_short),
                     count: count,
                     tooltip: I18n.l(created_at.to_date, format: :day_month)
                   }
                 end
    end
    helper_method :visits_per_day

    private def visits_per_month
      Ahoy::Visit.without_users(tracking_blacklist).one_year
                 .group_by_month(:started_at).count
                 .map do |started_at, count|
        {
          label: I18n.l(started_at.to_date, format: :month_year_short),
          count: count,
          tooltip: I18n.l(started_at.to_date, format: :month_year)
        }
      end
    end
    helper_method :visits_per_month

    private def registrations_per_month
      User.where('created_at > ?', Time.zone.now - 1.year)
          .group_by_month(:created_at)
          .count
          .map do |created_at, count|
            {
              label: I18n.l(created_at.to_date, format: :month_year_short),
              count: count,
              tooltip: I18n.l(created_at.to_date, format: :month_year)
            }
          end
    end
    helper_method :registrations_per_month

    private def components_by_class
      transform_for_chart(
        Component.group(:component_class).count
             .map { |label, count| { (label.present? ? I18n.t("filter.component.class.items.#{label.downcase}") : I18n.t('labels.unknown')) => count } }
             .reduce(:merge)
      )
    end
    helper_method :components_by_class

    private def models_by_size
      transform_for_chart(
        Model.group(:size).count
             .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
             .reduce(:merge)
      )
    end
    helper_method :models_by_size

    private def models_by_production_status
      transform_for_chart(
        Model.group(:production_status).count
             .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
             .reduce(:merge)
      )
    end
    helper_method :models_by_production_status

    private def models_by_manufacturer
      transform_for_chart(
        Manufacturer.with_model
                    .map { |m| { m.name => m.models.count } }
                    .reduce(:merge)
      )
    end
    helper_method :models_by_manufacturer

    private def models_by_classification
      transform_for_chart(
        Model.group(:classification).count
             .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
             .reduce(:merge)
      )
    end
    helper_method :models_by_classification

    private def online_count
      Ahoy::Event.without_users(tracking_blacklist)
                 .select(:visit_id).distinct
                 .where('time > ?', 15.minutes.ago).count
    end
    helper_method :online_count

    private def tracking_blacklist
      @tracking_blacklist ||= User.where(tracking: false).pluck(:id)
    end
    helper_method :tracking_blacklist

    private def transform_for_chart(data)
      data.sort_by { |_label, count| count }.reverse
          .each_with_index.map do |(label, count), index|
            point = {
              name: label,
              y: count
            }
            if index.zero?
              point[:selected] = true
              point[:sliced] = true
            end
            point
          end
    end
  end
end
