# frozen_string_literal: true

module ApiAuthorization
  extend ActiveSupport::Concern

  included do
    def current_user
      @current_user ||= current_api_user
    end
    helper_method :current_user

    def current_ability
      @current_ability ||= Ability.new(current_user)
    end
  end
end
