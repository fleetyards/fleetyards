# frozen_string_literal: true

module Api
  module V1
    class FleetMembersController < ::Api::BaseController
      include FleetMemberFiltersConcern
      include TransferTargetFilterConcern

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:slug]))
      end

      after_action -> { pagination_header(:members) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create update accept_request decline_request promote demote destroy remind_verification]

      before_action :set_fleet, only: %i[index show create update accept_request decline_request promote demote destroy remind_verification]
      before_action :set_member, only: %i[show accept_request decline_request promote demote destroy remind_verification]

      def index
        authorize! with: FleetMembershipPolicy, context: {fleet: @fleet}

        scope = @fleet.fleet_memberships.kept
        # In SQL rather than over the rendered page: the roster is paginated and
        # searched server-side, so filtering afterwards would thin one page at a
        # time and leave the Link header pointing at counts it never returned.
        scope = scope.where(user: ::User.receiving_transfers) if transfer_targets_only?

        normalize_sort_params(member_query_params)
        member_query_params["sorts"] = sorting_params(FleetMembership, member_query_params["sorts"])

        @q = scope.ransack(member_query_params)
        result = FleetMembership.where(
          FleetMembership.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
        )
          .order(@q.result.order_values)
          .includes(*FleetMembership::ROSTER_PRELOADS)
          .joins(:user)

        @members = result_with_pagination(result, per_page(FleetMembership))
      end

      # `set_member` has already found and authorized it. Reading one member on
      # its own is what a notification about a membership needs: it links to a
      # request that may long since have been answered, and the answer is the
      # member's state.
      def show
      end

      def create
        user = User.find_by(normalized_username: params[:username]&.downcase)

        @member = @fleet.fleet_memberships.new(
          user: user,
          fleet_role: @fleet.default_member_role,
          invited_by: current_resource_owner.id
        )

        authorize! @member

        if @member.save_without_conflict
          @member.invite!
          render :create, status: :created
        else
          render json: ValidationError.new("fleet_members.create", errors: @member.errors), status: :bad_request
        end
      end

      def accept_request
        unless @member.answer_request(accept: true, author_id: current_resource_owner.id) == :done
          render json: ValidationError.new("fleet_members.accept", errors: @member.errors), status: :bad_request
        end
      end

      def decline_request
        # The endpoint also withdraws an invitation, which is not a join
        # request and keeps its plain transition.
        declined = if @member.invited?
          @member.decline!
        else
          @member.answer_request(accept: false, author_id: current_resource_owner.id) == :done
        end

        unless declined
          render json: ValidationError.new("fleet_members.decline", errors: @member.errors), status: :bad_request
        end
      end

      def promote
        @member.promote
      end

      def demote
        return if @member.demote

        render json: ValidationError.new("fleet_members.demote", message: I18n.t("validation_error.fleet_memberships.demote_not_permitted")), status: :bad_request
      end

      # Tells the member what keeps them from being verified against the
      # fleet's RSI org, through whichever channels they chose. Once a week at
      # most: it is a nudge from their fleet, not a way to flood their inbox.
      def remind_verification
        gap = @fleet.rsi_sid.present? && @member.accepted? && @member.verification_gap
        unless gap
          return render json: ValidationError.new("fleet_members.remind_verification", message: I18n.t("validation_error.fleet_memberships.nothing_to_verify")), status: :bad_request
        end

        if @member.verification_reminded_at&.after?(FleetMembership::VERIFICATION_REMINDER_COOLDOWN.ago)
          return render json: ValidationError.new("fleet_members.remind_verification", message: I18n.t("validation_error.fleet_memberships.verification_recently_reminded")), status: :bad_request
        end

        user = @member.user
        I18n.with_locale(user.notification_locale) do
          Notification.notify!(
            user:,
            type: :fleet_verification_requested,
            title: I18n.t("notifications.fleet_verification_requested.title", fleet: @fleet.name),
            body: I18n.t("notifications.fleet_verification_requested.#{gap}", fleet: @fleet.name, sid: @fleet.rsi_sid),
            link: Rails.application.routes.url_helpers.frontend_profile_settings_path,
            icon: "fa-duotone fa-badge-check",
            record: @member
          )
        end

        head :no_content
      end

      # Discarded like a member leaving, with whoever removed them on the
      # version, so the fleet keeps the record that they were in: a join role
      # picked later must not admit them as if they never were.
      def destroy
        @member.author_id = current_resource_owner.id
        return if @member.discard

        render json: ValidationError.new("fleet_members.destroy", errors: @member.errors), status: :bad_request
      end

      # Not covered by `set_member`: that authorizes the rule matching the
      # action name, and `update?` is the self-service rule the membership
      # endpoint owns. Setting a nickname acts on someone else, so it asks for
      # `update_nickname?` instead.
      def update
        @member = find_member!

        authorize! @member, to: :update_nickname?

        return if @member.update(member_nickname_params)

        render json: ValidationError.new("fleet_members.update", errors: @member.errors), status: :bad_request
      end

      private def roster_filters?
        true
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def set_member
        @member = find_member!

        authorize! @member
      end

      private def find_member!
        @fleet.fleet_memberships.kept
          .includes(:user)
          .joins(:user)
          .find_by!(users: {normalized_username: params[:username].downcase})
      end

      private def member_nickname_params
        authorized(params, as: :update_nickname, with: FleetMembershipPolicy, context: {fleet: @fleet})
      end
    end
  end
end
