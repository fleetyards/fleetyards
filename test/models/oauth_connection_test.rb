# == Schema Information
#
# Table name: oauth_connections
#
#  id         :uuid             not null, primary key
#  provider   :string
#  uid        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_oauth_connections_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class OauthConnectionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
