# frozen_string_literal: true

module Api
  module V1
    module Me
      # The key a supporter puts in a donation so the payment can be matched to
      # their account.
      #
      # Read only, and deliberately not rotatable: a recurring donation carries
      # the message written when it was set up, so a new key would silently stop
      # every future payment from that subscription matching. The key grants no
      # access -- the worst a leaked one does is let somebody else's money credit
      # this account -- so there is nothing rotation would protect.
      class SupporterClaimKeysController < ::Api::BaseController
        before_action :authenticate_user!, only: []
        before_action -> { doorkeeper_authorize! "user", "user:read" },
          unless: :user_signed_in?,
          only: %i[show]

        skip_verify_authorized only: %i[show]

        # Generated on first read rather than behind a separate action. A key is
        # wanted at the moment somebody is about to donate, and making them ask
        # for one first is a detour with nothing at the end of it -- there is no
        # decision to make and nothing is disclosed by having one.
        def show
          @user = current_resource_owner
          @user.ensure_claim_key!
          render :show
        end
      end
    end
  end
end
