# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: components
#
#  id                    :uuid             not null, primary key
#  ammunition            :string
#  category              :string
#  component_class       :string
#  component_sub_type    :string
#  component_type        :string
#  description           :text
#  durability            :string
#  grade                 :string
#  heat_connection       :string
#  hidden                :boolean          default(FALSE)
#  inventory_consumption :string
#  item_class            :integer
#  item_type             :string
#  name                  :string(255)
#  power_connection      :string
#  sc_key                :string
#  sc_ref                :string
#  size                  :string(255)
#  slug                  :string
#  tracking_signal       :integer
#  type_data             :string
#  version               :string
#  created_at            :datetime
#  updated_at            :datetime
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#  index_components_on_sc_key           (sc_key) UNIQUE
#
class ComponentTest < ActiveSupport::TestCase
  setup do
    @component = create(:component, name: "FR-66 Shield", sc_key: "fr66", version: "0.0.1-live.1")
  end

  test "keeps a version when the spec changes" do
    assert_difference -> { @component.paper_trail_versions.count }, 1 do
      @component.update!(name: "FR-66 Shield Generator")
    end

    assert_equal "FR-66 Shield", @component.paper_trail_versions.last.reify.name
  end

  # An import touches every component it sees, and `version` moves on all of
  # them. Tracking it would write a history row per component per run and bury
  # the changes worth reading.
  test "keeps no version when only the build it was last seen in moves" do
    assert_no_difference -> { @component.paper_trail_versions.count } do
      @component.update!(version: Rails.configuration.sc_data[:version])
    end
  end

  test "rejects a second component with the same sc_key" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      Component.create!(name: "Copy", sc_key: "fr66")
    end
  end
end
