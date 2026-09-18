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
#  required_tags         :string
#  sc_key                :string
#  sc_ref                :string
#  size                  :string(255)
#  slug                  :string
#  tags                  :string
#  tracking_signal       :integer
#  type_data             :jsonb
#  version               :string
#  created_at            :datetime
#  updated_at            :datetime
#  manufacturer_id       :uuid
#
# Indexes
#
#  index_components_on_manufacturer_id  (manufacturer_id)
#  index_components_on_name             (name)
#  index_components_on_sc_key           (sc_key) UNIQUE
#  index_components_on_slug             (slug) UNIQUE
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
      @component.update!(version: ScData::Source.version)
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
    # Something else has to carry the configured build. With nothing loaded at
    # it, `ScData::Source#served` falls back to the newest build there is --
    # which in a test that creates exactly one is the very build it means to
    # call retired.
    create(:component_build, component: create(:component, :without_build),
      environment: ScData::Source.environment, version: ScData::Source.version)

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
    # As above: without a configured build to serve, the old one below is what
    # gets served and nothing is retired.
    create(:component_build, component: create(:component, :without_build),
      environment: ScData::Source.environment, version: ScData::Source.version)

    assert component.update_with_facts({name: "Corrected"})

    assert_equal "Old Name", old.reload.name
  end

  # Everything below sets a build value that *disagrees* with the column. While
  # both are written they are identical, so a filter reading the wrong one still
  # passes every other test in this file -- disagreement is the only way to show
  # which side answered.
  test "a text filter matches the name the build carries" do
    component = create(:component, :without_build, name: "Column Name")
    create(:component_build, component:, name: "Gorgon Shield")

    result = Component.with_facts.ransack(name_cont: "Gorgon").result

    assert_equal [component.id], result.pluck(:id)
  end

  test "a type filter follows the build, not the column" do
    component = create(:component, :without_build, item_type: "old_type")
    create(:component_build, component:, item_type: "Cooler")

    assert_equal [component.id], Component.with_facts.ransack(item_type_eq: "Cooler").result.pluck(:id)
    assert_empty Component.with_facts.ransack(item_type_eq: "old_type").result.pluck(:id)
  end

  # The ransacker has to keep its formatter, or the enum name never reaches the
  # integer the column stores.
  test "an enum filter follows the build" do
    component = create(:component, :without_build, item_class: nil)
    create(:component_build, component:, item_class: :military)

    assert_equal [component.id], Component.with_facts.ransack(item_class_eq: "military").result.pluck(:id)
  end

  test "the hidden filter follows the build" do
    component = create(:component, :without_build, hidden: false)
    create(:component_build, component:, hidden: true)

    assert_equal [component.id], Component.with_facts.ransack(hidden_eq: true).result.pluck(:id)
    assert_empty Component.with_facts.ransack(hidden_eq: false).result.pluck(:id)
  end

  # The reader falls back to the column for a component no load ever described, so
  # the filter has to as well on the path that shows such a component.
  test "a filter falls back to the column when there is no build at all" do
    component = create(:component, :without_build, item_type: "hand_made")

    assert_equal [component.id],
      Component.with_facts(false).ransack(item_type_eq: "hand_made").result.pluck(:id)
  end

  # And is left out of the catalogue, which is what makes the fallback droppable
  # on the fast path: nothing the current build does not describe is in it.
  test "the current catalogue leaves out a component with no build" do
    create(:component, :without_build, item_type: "hand_made")

    assert_empty Component.with_facts.ransack(item_type_eq: "hand_made").result.pluck(:id)
  end

  test "sorting orders by the name the build carries" do
    first = create(:component, :without_build, name: "Zulu Column")
    second = create(:component, :without_build, name: "Alpha Column")
    create(:component_build, component: first, name: "Alpha Build")
    create(:component_build, component: second, name: "Zulu Build")

    ordered = Component.with_facts.order(Component.fact_sql(:name).asc).pluck(:id)

    assert_equal [first.id, second.id], ordered
  end

  test "the facet lists come from the build" do
    component = create(:component, :without_build, category: "old_category")
    create(:component_build, component:, category: "coolers", component_sub_type: "Military")

    assert_equal ["coolers"], Component.categories
    assert_equal ["Military"], Component.sub_types
  end

  test "the facet lists narrow by the build's category" do
    cooler = create(:component, :without_build)
    shield = create(:component, :without_build)
    create(:component_build, component: cooler, category: "coolers", component_sub_type: "Military")
    create(:component_build, component: shield, category: "shields", component_sub_type: "Civilian")

    assert_equal ["Military"], Component.sub_types(category: "coolers")
  end

  test ".current_version narrows to the patch the game ships, or opts out" do
    current = create(:component, version: ScData::Source.version)
    retired = create(:component, version: "0.0.1-live.1")

    assert_equal [current.id], Component.current_version.pluck(:id)
    assert_includes Component.current_version(false).pluck(:id), retired.id
  end

  test "a name nobody else carries slugs to the name alone" do
    component = create(:component, name: "Bulldog Repeater", sc_key: "behr_repeater_s3")

    assert_equal "bulldog-repeater", component.slug
  end

  test "a shared name disambiguates on sc_key, which survives a reload" do
    first = create(:component, name: "Manned Turret", sc_key: "aegs_hammerhead_turret_rear")
    second = create(:component, name: "Manned Turret", sc_key: "anvl_valkyrie_turret_top")

    assert_equal "manned-turret-anvl-valkyrie-turret-top", second.slug
    refute_equal first.slug, second.slug

    second.touch
    assert_equal "manned-turret-anvl-valkyrie-turret-top", second.reload.slug
  end

  # A load saves every component it sees. Deriving the slug again costs two
  # existence checks to land on the value already in the column, so a save that
  # moves neither name nor sc_key skips it entirely.
  test "a save that changes neither name nor sc_key spends no query on the slug" do
    component = create(:component, name: "Manned Turret", sc_key: "aegs_idris_turret")

    statements = statements_for { component.update!(description: "unchanged name") }

    assert_empty statements.grep(/FROM "components" WHERE "components"\."(name|slug)"/)
  end

  test "a rename still re-derives the slug" do
    component = create(:component, :without_build, name: "Old Name", sc_key: "behr_laser_s3")

    component.update!(name: "New Name")

    assert_equal "new-name", component.reload.slug
  end

  # `name` reads through to the build, so a correction has to reach the build to
  # reach the slug. Writing the column alone leaves both the reader and the slug
  # on the build's answer -- which is how this behaved before the slug was
  # unique, and is why an admin correction goes through `update_with_facts`.
  test "a correction that reaches the build catches the slug up on the next save" do
    component = create(:component, name: "Old Name", version: ScData::Source.version)

    # The build is written after the row is saved, so the slug is one save
    # behind a rename -- true before this column was unique, and unchanged.
    component.update_with_facts({name: "Corrected"})
    assert_equal "Corrected", component.reload.name
    assert_equal "old-name", component.slug

    component.update!(description: "any later save")

    assert_equal "corrected", component.reload.slug
  end

  # The incumbent's URL is the one people have already bookmarked, and a load
  # saves every component it sees. Before the settled check, the arrival of a
  # second "Manned Turret" rewrote the first one's bare slug to the suffixed
  # form on its very next save.
  test "an incumbent keeps its slug when a duplicate name arrives later" do
    incumbent = create(:component, :without_build, name: "Manned Turret", sc_key: "aegs_idris_t1")
    assert_equal "manned-turret", incumbent.slug

    create(:component, :without_build, name: "Manned Turret", sc_key: "anvl_valk_t2")
    incumbent.update!(description: "the next import saves it again")

    assert_equal "manned-turret", incumbent.reload.slug
  end

  test "a component with no name has no slug, so the index tolerates the 3048 of them" do
    first = create(:component, name: nil, sc_key: "htnk_nameless_one")
    second = create(:component, name: nil, sc_key: "htnk_nameless_two")

    assert_nil first.slug
    assert_nil second.slug
  end

  test "a shared name with no sc_key to separate it falls back to a counter" do
    create(:component, name: "Internal Tank", sc_key: nil)
    second = create(:component, name: "Internal Tank", sc_key: nil)

    assert_equal "internal-tank-2", second.slug
  end

  # `type_data` was a YAML string tagged as a HashWithIndifferentAccess, so
  # every reader got symbol access for free -- `Hardpoint#thruster_class` digs
  # `:thruster_class`. A plain jsonb column hands back a bare Hash, which would
  # answer nil there without raising, so the column keeps a type that wraps it.
  test "a metric read out of jsonb still answers to a symbol" do
    component = create(:component, type_data: {"thruster_class" => "main", "power_ranges" => {"low" => {"start" => 1.0}}})

    stored = component.reload.type_data

    assert_equal "main", stored[:thruster_class]
    assert_equal "main", stored["thruster_class"]
    assert_in_delta 1.0, stored.dig(:power_ranges, :low, :start)
  end

  test "type_data is queryable as jsonb, which is the point of the column type" do
    create(:component, name: "Weak Shield", type_data: {"max_health" => 100})
    strong = create(:component, name: "Strong Shield", type_data: {"max_health" => 9000})

    found = Component.where("(type_data ->> 'max_health')::numeric > ?", 1000)

    assert_equal [strong.id], found.pluck(:id)
  end

  test "the database refuses two components on one slug" do
    first = create(:component, name: "Omnisky VI", sc_key: "klwe_laser_s3")
    second = create(:component, name: "Omnisky IX", sc_key: "klwe_laser_s4")

    # Past the callback on purpose: the point is the index, not the derivation.
    assert_raises(ActiveRecord::RecordNotUnique) do
      second.update_column(:slug, first.slug)
    end
  end

  # The export prefixes the prose with a metadata block and escapes its newlines
  # as a literal backslash-n. `description` reads through to the build, so
  # normalising only on save left every row loaded earlier still serving it.
  test "a description reads as prose, with the export's metadata block stripped" do
    raw = 'Item Type: Quantum Drive\\nManufacturer: Wei-Tek\\nSize: 3\\n\\nAdvanced plating provides durability.'
    component = create(:component, :without_build)
    create(:component_build, component:, description: raw)

    assert_equal "Advanced plating provides durability.", component.reload.description
  end

  # It ran every word together before -- `gsub(/[[:space:]]+/, "")` deleted the
  # spaces along with the newlines.
  test "a description keeps the spaces between its words" do
    component = create(:component, :without_build)
    create(:component_build, component:, description: "Two\nlines of prose.")

    assert_equal "Two lines of prose.", component.reload.description
  end

  test "a description with no metadata block is left as it is" do
    component = create(:component, :without_build)
    create(:component_build, component:, description: "Tractor Beam")

    assert_equal "Tractor Beam", component.reload.description
  end

  # The opening paragraph of an ordinary description is not a metadata block.
  # Taking the first segment on faith discarded it, and the save callbacks then
  # stored the truncation -- the text was gone for good.
  test "a description with two paragraphs and no metadata keeps both" do
    component = create(:component, :without_build)
    create(
      :component_build,
      component:, description: 'First paragraph of real prose.\\n\\nSecond paragraph.'
    )

    assert_equal(
      "First paragraph of real prose. Second paragraph.",
      component.reload.description
    )
  end

  # The export writes far more keys than the obvious five, and separates a key
  # from its value with a non-breaking space often enough to matter.
  test "a metadata block is recognised by its shape, not a list of known keys" do
    component = create(:component, :without_build)
    create(
      :component_build,
      component:,
      description: "Capacity: 1.2 SCU\\nFull Strength Distance: 200 m\\nClass:\u00A0Competition\\n\\nThe prose."
    )

    assert_equal "The prose.", component.reload.description
  end

  # A paragraph that opens with a colon is prose, and runs longer than a value.
  test "a long opening line that reads as a sentence is not a metadata block" do
    component = create(:component, :without_build)
    create(
      :component_build,
      component:,
      description: 'Warning: do not operate this device inside an atmosphere under any circumstances.\\n\\nMore.'
    )

    assert_includes component.reload.description, "Warning: do not operate"
  end

  private def statements_for
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      statements << payload[:sql] unless payload[:name] == "SCHEMA"
    end

    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
