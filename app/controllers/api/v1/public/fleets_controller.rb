# frozen_string_literal: true

module Api
  module V1
    module Public
      class FleetsController < ::Api::PublicBaseController
        before_action :set_fleet

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:slug]))
        end

        def show
        end

        private def set_fleet
          @fleet = Fleet.find_by!(slug: params[:slug])

          authorize! @fleet, to: :show?, with: ::Public::FleetPolicy
        end
      end
    end
  end
end
