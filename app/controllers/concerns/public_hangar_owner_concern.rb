# frozen_string_literal: true

# What a public endpoint for one ship of a hangar checks first: the hangar is
# visible (or opened by its share token), and its owner has the vehicle overview
# switched on. The owner shares the ship, so it is the owner's flag that
# decides, not the visitor's -- who may well be signed out.
module PublicHangarOwnerConcern
  extend ActiveSupport::Concern

  included do
    include HangarShareTokenConcern

    before_action :set_user
    before_action :check_owner_feature
  end

  private def set_user
    @user = User.find_by!(normalized_username: params[:hangar_username].downcase)

    authorize! @user, to: :show?, with: ::Public::UserPolicy
  end

  private def check_owner_feature
    return if Flipper.enabled?(:vehicle_overview, @user)

    render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
  end
end
