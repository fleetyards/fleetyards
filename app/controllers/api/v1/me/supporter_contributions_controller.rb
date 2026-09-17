# frozen_string_literal: true

module Api
  module V1
    module Me
      # A supporter's own contributions, and the single thing they may change
      # about one: which fleet it is for.
      #
      # Scoped to the signed-in account rather than authorized per record. A
      # contribution nobody has been linked to has no owner to ask, and one
      # linked to somebody else is not in this collection at all -- so the scope
      # *is* the authorization, and there is no record here a policy could be
      # asked about.
      class SupporterContributionsController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[index]
        before_action -> { doorkeeper_authorize! "user", "user:write" },
          unless: :user_signed_in?,
          only: %i[update]

        # After the doorkeeper callbacks, so an unauthenticated request still gets
        # a 401 rather than being told the feature does not exist.
        before_action :check_fleet_subscriptions_feature

        skip_verify_authorized only: %i[index update]

        def index
          @contributions = my_contributions
            .includes(fleet: {logo_attachment: :blob})
            .order(started_at: :desc)

          render :index
        end

        def update
          @contribution = my_contributions.find(params[:id])

          if @contribution.update(nomination_params)
            # A nomination change is not a payment event, and it is the other
            # half of what the reconciler has to answer to (D9).
            ::Subscriptions::SyncJob.perform_async

            render :show
          else
            render json: ValidationError.new("supporter_contributions.nominate",
              errors: @contribution.errors), status: :bad_request
          end
        end

        private def check_fleet_subscriptions_feature
          return if feature_enabled?("fleet_subscriptions")

          render json: {code: "forbidden", message: "This feature is not available"},
            status: :forbidden
        end

        private def my_contributions
          ::SupporterContribution.where(user_id: current_resource_owner.id)
        end

        # `fleetId` is required by the request schema, so request validation
        # answers an absent key with a 400 before anything here runs -- there is
        # no "leave it alone" case to handle. An empty string is normalised to
        # nil so clearing works whichever way a client spells it.
        private def nomination_params
          {fleet_id: params.permit(:fleet_id)[:fleet_id].presence}
        end
      end
    end
  end
end
