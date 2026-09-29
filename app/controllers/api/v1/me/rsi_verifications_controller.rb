# frozen_string_literal: true

module Api
  module V1
    module Me
      class RsiVerificationsController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[show]
        before_action -> { doorkeeper_authorize! "user", "user:write" },
          unless: :user_signed_in?,
          only: %i[create check destroy]

        skip_verify_authorized only: %i[show create check destroy]

        before_action :set_user

        def show
        end

        def create
          @user.generate_rsi_verification_token!

          render :show, status: :created
        end

        # A check inside the cooldown answers with the state as it is, so a
        # second click is not an error, just not another request to RSI.
        def check
          if @user.rsi_handle.blank? || @user.rsi_verification_token.blank?
            render json: ValidationError.new("user_rsi_verification.check"), status: :bad_request
            return
          end

          # Under the lock, so two tabs pressing Check at once start one
          # request to RSI rather than two.
          checked_at = @user.with_lock do
            next if @user.rsi_handle_verified? || @user.rsi_verification_cooling_down?

            # To the microsecond the column keeps, so the job's copy of it still
            # names this check once read back.
            Time.current.floor(6).tap do |now|
              # rubocop:disable Rails/SkipsModelValidations
              @user.update_columns(
                rsi_verification_status: :pending,
                rsi_verification_checked_at: now,
                updated_at: Time.current
              )
              # rubocop:enable Rails/SkipsModelValidations
            end
          end

          if checked_at
            UserRsiVerificationJob.perform_async(@user.id, UserRsiVerification.generation_of(checked_at))
          end

          render :show
        end

        # Citizen iD would verify the handle again on the next sign-in, so a
        # handle it proved is released by disconnecting it instead.
        def destroy
          if @user.rsi_handle_verified_via_citizenid?
            render json: ValidationError.new("user_rsi_verification.destroy"), status: :bad_request
            return
          end

          @user.revoke_rsi_handle_verification!

          render :show
        end

        private def set_user
          @user = current_resource_owner
        end
      end
    end
  end
end
