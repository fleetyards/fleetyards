# frozen_string_literal: true

# What a public endpoint for one ship of a hangar checks first: the hangar is
# visible, or opened by its share token.
module PublicHangarOwnerConcern
  extend ActiveSupport::Concern

  included do
    include HangarShareTokenConcern

    before_action :set_user
  end

  private def set_user
    @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

    authorize! @user, to: :show?, with: ::Public::UserPolicy
  end
end
