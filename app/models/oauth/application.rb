# == Schema Information
#
# Table name: oauth_applications
#
#  id           :uuid             not null, primary key
#  confidential :boolean          default(TRUE), not null
#  name         :string           not null
#  owner_type   :string
#  redirect_uri :text
#  scopes       :string           default(""), not null
#  secret       :string(512)      not null
#  uid          :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  owner_id     :uuid
#
# Indexes
#
#  index_oauth_applications_on_owner_id_and_owner_type  (owner_id,owner_type)
#  index_oauth_applications_on_uid                      (uid) UNIQUE
#
module Oauth
  class Application < ApplicationRecord
    include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

    belongs_to :owner, class_name: "User", foreign_key: :owner_id

    encrypts :secret
  end
end
