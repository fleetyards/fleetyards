# == Schema Information
#
# Table name: oauth_access_tokens
#
#  id                     :uuid             not null, primary key
#  expires_in             :integer
#  previous_refresh_token :string           default(""), not null
#  refresh_token          :string(512)
#  revoked_at             :datetime
#  scopes                 :string
#  token                  :string(512)      not null
#  created_at             :datetime         not null
#  application_id         :uuid             not null
#  resource_owner_id      :uuid
#
# Indexes
#
#  index_oauth_access_tokens_on_application_id     (application_id)
#  index_oauth_access_tokens_on_refresh_token      (refresh_token) UNIQUE
#  index_oauth_access_tokens_on_resource_owner_id  (resource_owner_id)
#  index_oauth_access_tokens_on_token              (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (application_id => oauth_applications.id)
#  fk_rails_...  (resource_owner_id => users.id)
#
module Oauth
  class AccessToken < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken

    encrypts :token, :refresh_token, deterministic: true
  end
end
