# frozen_string_literal: true

module Api
  module V1
    class RaffleEntriesController < ::Api::BaseController
      include RafflesFeatureConcern

      before_action :check_raffles_feature
      before_action :set_raffle

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.raffle"))
      end

      def create
        @entry = @raffle.entries.new(user: current_resource_owner, conditions_accepted: params[:conditions_accepted])

        authorize! @entry, with: ::RaffleEntryPolicy

        if @entry.save
          @viewer_entries = {@raffle.id => @entry}
          render "api/v1/raffles/show", status: :created
        else
          render json: ValidationError.new("raffle_entry.create", errors: @entry.errors), status: :bad_request
        end
      rescue ActiveRecord::RecordNotUnique
        render json: ValidationError.new("raffle_entry.create", message: I18n.t("validation_error.raffle_entry.messages.already_entered")), status: :bad_request
      end

      def destroy
        @entry = @raffle.entries.find_by!(user: current_resource_owner)

        authorize! @entry, with: ::RaffleEntryPolicy

        @entry.destroy!
        @raffle.reload
        @viewer_entries = {}
        render "api/v1/raffles/show"
      end

      private def set_raffle
        @raffle = Raffle.published.find(params[:raffle_id])
      end
    end
  end
end
