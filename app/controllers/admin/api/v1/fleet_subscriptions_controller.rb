# frozen_string_literal: true

module Admin
  module Api
    module V1
      # Where a subscription is granted by hand: a comped partner org, an
      # answered support ticket, a revocation.
      #
      # `granted_via: "manual"` is not an escape hatch (D2) -- it is what keeps
      # a grant out of the reconciler's reach. `Subscriptions::Sync` closes only
      # what it seeded, so anything opened here survives every import that knows
      # nothing about it.
      class FleetSubscriptionsController < ::Admin::Api::BaseController
        before_action :set_fleet_subscription, only: %i[show update destroy]

        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.fleet_subscription"))
        end

        # The partial unique index is the authority on one-open-per-fleet, so a
        # race that loses it is answered as a validation failure rather than as
        # a 500. Two admins comping the same fleet at once is exactly the case.
        rescue_from ActiveRecord::RecordNotUnique do |_exception|
          render json: ValidationError.new(
            "fleet_subscription.#{action_name}",
            message: I18n.t("messages.fleet_subscriptions.already_open")
          ), status: :bad_request
        end

        def index
          authorize! with: ::Admin::FleetSubscriptionPolicy

          normalize_sort_params(fleet_subscription_query_params)
          fleet_subscription_query_params["sorts"] =
            sorting_params(FleetSubscription, fleet_subscription_query_params[:sorts])

          q = FleetSubscription.ransack(fleet_subscription_query_params)

          @fleet_subscriptions = q.result(distinct: true)
            .includes(:fleet, supporter_contribution: :user)
            .page(page_params)
            .per(per_page(FleetSubscription))
        end

        def show
        end

        def create
          @fleet_subscription = FleetSubscription.new(
            create_params.merge(granted_via: "manual", author_id: current_user.id)
          )

          authorize! @fleet_subscription, with: ::Admin::FleetSubscriptionPolicy

          if @fleet_subscription.save
            # Not unconditional: `ended_at` is permitted here, so a grant can be
            # created already closed, or dated into the future -- neither is a
            # fleet that just gained anything.
            ::Subscriptions::Notifier.started(@fleet_subscription) if @fleet_subscription.active_on?

            return render :show, status: :created
          end

          render json: ValidationError.new("fleet_subscription.create",
            errors: @fleet_subscription.errors), status: :bad_request
        end

        # Closing is an update that writes `ended_at`. There is no separate
        # action for it: the history is the row, and a revocation is a date on
        # it rather than an event beside it.
        def update
          was_open = @fleet_subscription.open?
          was_active = @fleet_subscription.active_on?

          if @fleet_subscription.update(update_params.merge(author_id: current_user.id))
            # Only the transition, not every edit: correcting a note on an
            # already-closed subscription is not news, and a fleet told twice
            # that it lapsed learns to ignore the message. An admin closing a
            # contribution-backed grant is `manual` -- the donation may still be
            # running, and blaming it would be false.
            ::Subscriptions::Notifier.announce(@fleet_subscription,
              was_open:, was_active:, cause: :manual)

            return render :show
          end

          render json: ValidationError.new("fleet_subscription.update",
            errors: @fleet_subscription.errors), status: :bad_request
        end

        # For a grant that should never have existed. Closing is the normal
        # path -- this one leaves a version too, so a removed entitlement is
        # still answerable for.
        def destroy
          # paper_trail files a destroy version for this model, and a version
          # with no author is filtered out of the recent-changes feed -- so the
          # one action that removes an entitlement would be the one nobody could
          # see afterwards.
          @fleet_subscription.author_id = current_user.id
          was_open = @fleet_subscription.open?
          was_active = @fleet_subscription.active_on?

          if @fleet_subscription.destroy
            # Deleting an entitlement takes access away exactly as closing one
            # does, so it cannot be the quiet path out.
            ::Subscriptions::Notifier.announce(@fleet_subscription,
              was_open:, was_active:, cause: :manual)

            return
          end

          render json: ValidationError.new("fleet_subscription.destroy",
            errors: @fleet_subscription.errors), status: :bad_request
        end

        private def set_fleet_subscription
          @fleet_subscription = FleetSubscription.find(params[:id])

          authorize! @fleet_subscription, with: ::Admin::FleetSubscriptionPolicy
        end

        private def create_params
          params.permit(:fleet_id, :started_at, :ended_at, :note,
            :update_reason, :update_reason_description)
        end

        # No `fleet_id`. A subscription's fleet is fixed when it is opened:
        # moving a seeded row to another fleet would leave it pointing at a
        # contribution that names the first one, and the next sync would then
        # open a second row for the original fleet and close the moved one.
        # Closing and opening a new one is the coherent way to say that.
        private def update_params
          params.permit(:started_at, :ended_at, :note,
            :update_reason, :update_reason_description)
        end

        private def fleet_subscription_query_params
          @fleet_subscription_query_params ||= params.permit(q: [
            :fleet_id_eq, :granted_via_eq, :ended_at_null,
            :started_at_gteq, :started_at_lteq,
            :supporter_contribution_id_null,
            :fleet_name_cont, :fleet_slug_eq,
            :s, :sorts, s: [], sorts: []
          ]).fetch(:q, {})
        end
      end
    end
  end
end
