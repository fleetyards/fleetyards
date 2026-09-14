# frozen_string_literal: true

module Api
  module V1
    module Me
      # The key a supporter puts in a donation so the payment can be matched to
      # their account. Shaped like the personal calendar subscription beside it:
      # reading never creates one, because most accounts never donate.
      class SupporterClaimKeysController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[show]
        before_action -> { doorkeeper_authorize! "user", "user:write" },
          unless: :user_signed_in?,
          only: %i[create rotate]

        skip_verify_authorized only: %i[show create rotate]

        def show
          @user = current_resource_owner
          render :show
        end

        def create
          @user = current_resource_owner
          @user.ensure_claim_key!
          render :show
        end

        # A key is public by design -- it travels through a donation message
        # somebody else processes -- so rotating is the answer to it ending up
        # somewhere unwanted, not deleting it.
        def rotate
          @user = current_resource_owner
          @user.rotate_claim_key!
          render :show
        end
      end
    end
  end
end
