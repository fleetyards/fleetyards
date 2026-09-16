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
            render :show
          else
            render json: ValidationError.new("supporter_contributions.nominate",
              errors: @contribution.errors), status: :bad_request
          end
        end

        private def my_contributions
          ::SupporterContribution.where(user_id: current_resource_owner.id)
        end

        # `fetch` rather than `permit`, because an absent key and an explicit
        # null mean different things here and `permit` cannot tell them apart:
        # sending no key at all must not silently clear a nomination.
        private def nomination_params
          {fleet_id: params.fetch(:fleet_id, @contribution.fleet_id)}
        end
      end
    end
  end
end
