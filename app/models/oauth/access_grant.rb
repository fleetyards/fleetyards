module Oauth
  class AccessGrant < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessGrant

    encrypts :token, deterministic: true
  end
end
