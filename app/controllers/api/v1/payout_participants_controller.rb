# frozen_string_literal: true

module Api
  module V1
    class PayoutParticipantsController < ::Api::BaseController
      include PayoutLedgerScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read", "user" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write", "user:write" },
        unless: :user_signed_in?,
        only: %i[create destroy]

      before_action :set_payout_ledger
      before_action :check_tour_payouts_feature
      before_action :resolve_username, only: %i[create]
      before_action :set_payout_participant, only: %i[destroy]

      def index
        authorize! with: PayoutParticipantPolicy, context: ledger_context

        @payout_participants = @payout_ledger.payout_participants.includes(:user).order(:created_at)
      end

      def create
        @payout_participant = @payout_ledger.payout_participants.new(participant_attributes)
        @payout_participant.added_by = current_resource_owner

        authorize! @payout_participant, with: PayoutParticipantPolicy, context: ledger_context

        if @payout_participant.save
          render :show, status: :created
        else
          render json: ValidationError.new("payout_participants.create", errors: @payout_participant.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @payout_participant, with: PayoutParticipantPolicy, context: ledger_context

        if @payout_participant.destroy
          render :show
        else
          render json: ValidationError.new("payout_participants.destroy", errors: @payout_participant.errors), status: :bad_request
        end
      end

      private def participant_attributes
        attrs = authorized(params, with: PayoutParticipantPolicy, context: ledger_context).to_h
        attrs.delete("username")
        return attrs if @resolved_user.blank?

        attrs.merge("user_id" => @resolved_user.id, "name" => nil)
      end

      # The form offers a username rather than a uuid, because that is how a
      # person is named everywhere else on the site. A guest arrives with a
      # plain name and no lookup at all. Resolving it here rather than inside
      # participant_attributes lets the 404 halt the action instead of
      # rendering on top of it.
      private def resolve_username
        username = params[:username].presence
        return if username.blank?

        @resolved_user = User.find_by(normalized_username: username.to_s.downcase)
        return if @resolved_user.present?

        render json: {code: "not_found", message: "No user with that username"}, status: :not_found
      end

      private def set_payout_participant
        @payout_participant = @payout_ledger.payout_participants.find(params[:id])
      end
    end
  end
end
