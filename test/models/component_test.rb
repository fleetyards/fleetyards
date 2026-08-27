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
#  index_components_on_version          (version)
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

  # A record the export dropped keeps the values of the last build that described
  # it -- a hardpoint or a paint pointing at one has to resolve to something --
  # and says so, rather than serving them as if they were current.
  test "a retired component reads the last build that described it, and is marked" do
    component = create(:component, :without_build, name: "Column Name")
    create(
      :component_build,
      component:, environment: ScData::Source.environment,
      version: "0.0.1-live.1", name: "Gorgon", size: "3"
    )

    assert_equal "Gorgon", component.reload.name
    assert_equal "3", component.size
    assert_predicate component, :retired?
  end

  test "a component in the current build reads that build, and is not retired" do
    component = create(:component, :without_build, name: "Column Name")
    create(:component_build, component:, name: "Gorgon")

    assert_equal "Gorgon", component.reload.name
    assert_not_predicate component, :retired?
  end

  test "the current build wins over an earlier one" do
    component = create(:component, :without_build)
    create(:component_build, component:, version: "0.0.1-live.1", size: "1")
    create(:component_build, component:, size: "4")

    assert_equal "4", component.reload.size
  end

  # An admin can create a component by hand, and no load has given it a build yet.
  test "a component with no build at all falls back to its own columns" do
    component = create(:component, :without_build, name: "Hand Made", size: "2")

    assert_equal "Hand Made", component.reload.name
    assert_equal "2", component.size
    assert_predicate component, :retired?
  end

  # An enum-backed fact has to read as its name from the build too, not as the
  # integer the column stores.
  test "an enum fact read off the build keeps its name" do
    component = create(:component, :without_build)
    create(:component_build, component:, item_class: :military)

    assert_equal "military", component.reload.item_class
  end

  # And a serialized one as its structure. Six columns are YAML on Component; the
  # build has to match all six or the reader passes a raw string through, because
  # a string is not nil.
  test "a serialized fact read off the build keeps its structure" do
    component = create(:component, :without_build)
    create(:component_build, component:, type_data: {"beam" => true})

    assert_equal({"beam" => true}, component.reload.type_data)
  end

  # Without this the reader would go on serving the build's old value.
  test "#update_with_facts writes the correction to the build as well" do
    component = create(:component, name: "Typo", version: ScData::Source.version)

    assert component.update_with_facts({name: "Corrected"})

    assert_equal "Corrected", component.reload.name
    assert_equal "Corrected", component.build.name
  end

  test "#update_with_facts leaves a retired component's build alone" do
    component = create(:component, :without_build, name: "Typo")
    old = create(:component_build, component:, version: "0.0.1-live.1", name: "Old Name")

    assert component.update_with_facts({name: "Corrected"})

    assert_equal "Old Name", old.reload.name
  end

  test ".current_version narrows to the patch the game ships, or opts out" do
    current = create(:component, version: ScData::Source.version)
    retired = create(:component, version: "0.0.1-live.1")

    assert_equal [current.id], Component.current_version.pluck(:id)
    assert_includes Component.current_version(false).pluck(:id), retired.id
  end
end
