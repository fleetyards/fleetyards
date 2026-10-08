# frozen_string_literal: true

# Hands the hangar share link's token from `?share=` to Public::UserPolicy, the
# only policy that reads it. Kept to the hangar's own endpoints so no other
# public policy can come to accept a hangar token by declaring the same name.
module HangarShareTokenConcern
  extend ActiveSupport::Concern

  included do
    authorize :share_token, through: :share_token_param
  end

  private def share_token_param
    params[:share].presence
  end
end
