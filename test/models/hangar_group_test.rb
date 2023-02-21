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
#  hangar_groups_user_id_slug_index         (user_id,slug) UNIQUE
#  index_hangar_groups_on_user_id           (user_id)
#  index_hangar_groups_on_user_id_and_name  (user_id,name) UNIQUE
#
require "test_helper"

class HangarGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
