# frozen_string_literal: true

module Api
  class PublicBaseController < ::Api::BaseController
    # The OAuth scopes a token needs before these endpoints read as its owner;
    # without them it reads as anyone else. A fleet's members or a friend's
    # hangar are what fleet:read and hangar:read grant on the signed-in
    # endpoints, so a public twin must not hand them to a token without them.
    class_attribute :resource_owner_scopes, instance_writer: false, default: [].freeze

    FLEET_READER_SCOPES = %w[fleet fleet:read].freeze
    HANGAR_READER_SCOPES = %w[hangar hangar:read].freeze

    before_action :authenticate_user!, only: %i[]

    rescue_from ActionPolicy::Unauthorized do |exception|
      not_found
    end

    # Returns before `super` so a refused token never lands in `@current_user`,
    # where Devise would read it as a signed-in user.
    def current_resource_owner
      return if doorkeeper_token.present? && resource_owner_scopes.any? &&
        !doorkeeper_token.acceptable?(resource_owner_scopes)

      super
    end
  end
end
