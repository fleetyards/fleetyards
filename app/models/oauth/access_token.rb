module Oauth
  class AccessToken < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken

    encrypts :token, :refresh_token, deterministic: true
  end
end
