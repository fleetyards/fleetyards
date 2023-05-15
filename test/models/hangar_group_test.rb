# frozen_string_literal: true

# == Schema Information
#
# Table name: hangar_groups
#
#  id         :uuid             not null, primary key
#  color      :string
#  name       :string
#  public     :boolean          default(FALSE)
#  slug       :string
#  sort       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid
#
# Indexes
#
#  index_hangar_groups_on_user_id_and_name  (user_id,name) UNIQUE
#
require "test_helper"

class HangarGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
