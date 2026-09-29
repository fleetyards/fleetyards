# frozen_string_literal: true

module Admin
  module Api
    module V1
      class FleetFidClaimsController < ::Admin::Api::BaseController
        before_action :set_claim, only: %i[update cancel]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        def index
          authorize! with: ::Admin::FleetPolicy

          @claims = FleetFidClaim.open
            .includes(:claimant, :holder)
            .order(ends_at: :asc)
            .page(page_params)
            .per(per_page(FleetFidClaim))
        end

        # Only ever earlier: the grace period is what the holder was promised,
        # and an admin can shorten it but not keep a claim hanging over a fleet
        # for longer. One that is due now completes at once.
        def update
          ends_at = Time.zone.parse(params[:ends_at].to_s)

          # Under the lock, so a withdrawal or a completion that lands first
          # is not answered with a new deadline on a claim that is closed.
          shortened = @claim.with_lock do
            next false if !@claim.open? || ends_at.nil? || ends_at > @claim.ends_at

            @claim.update!(ends_at:)
          end

          unless shortened
            render json: ValidationError.new("fleet_fid_claim.update"), status: :bad_request
            return
          end

          @claim.complete! if @claim.ends_at <= Time.current

          render :show
        end

        def cancel
          unless @claim.cancel!(:admin)
            render json: ValidationError.new("fleet_fid_claim.cancel"), status: :bad_request
            return
          end

          render :show
        end

        private def set_claim
          @claim = FleetFidClaim.includes(:claimant, :holder).find(params[:id])

          authorize! @claim.claimant, with: ::Admin::FleetPolicy
        end
      end
    end
  end
end
