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
