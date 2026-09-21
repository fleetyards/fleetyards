# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: game_missions
#
#  id                          :uuid             not null, primary key
#  alignment                   :string
#  blueprint_pool_refs         :text             default([]), not null, is an Array
#  debug_name                  :string
#  description                 :text
#  difficulty_game_knowledge   :integer
#  difficulty_mechanical_skill :integer
#  difficulty_mental_load      :integer
#  difficulty_profile          :string
#  difficulty_risk_of_loss     :integer
#  generator_key               :string
#  kind                        :string
#  max_standing                :string
#  min_standing                :string
#  name                        :string
#  org_key                     :string
#  org_lawful                  :boolean
#  org_name                    :string
#  org_ref                     :string
#  released                    :boolean          default(TRUE), not null
#  reward_kinds                :text             default([]), not null, is an Array
#  sc_key                      :string           not null
#  sc_ref                      :string           not null
#  slug                        :string           not null
#  version                     :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_game_missions_on_org_name  (org_name)
#  index_game_missions_on_sc_key    (sc_key) UNIQUE
#  index_game_missions_on_sc_ref    (sc_ref) UNIQUE
#  index_game_missions_on_slug      (slug) UNIQUE
#  index_game_missions_on_version   (version)
#
class GameMissionTest < ActiveSupport::TestCase
  # From the key rather than the title: 2536 contracts share 836 titles, and
  # 902 of those titles carry a run-time span that is not a URL.
  test "generates a slug from the record key" do
    mission = create(:game_mission, sc_key: "foxwellenforcement_ambush_veryeasy")

    assert_equal "foxwellenforcement-ambush-veryeasy", mission.slug
  end

  test "two variants of the same mission keep their own slugs" do
    title = "Salvager Needed (Med. Supply of RMC)"
    first = create(:game_mission, sc_key: "adagio_rmc_stanton_m", name: title)
    second = create(:game_mission, sc_key: "adagio_rmc_pyro_m", name: title)

    assert_not_equal first.slug, second.slug
  end

  test "rejects a duplicate ref" do
    create(:game_mission, sc_ref: "beef")
    duplicate = build(:game_mission, sc_ref: "beef")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :sc_ref
  end

  # The build is what a reader sees, so an admin correction to the row alone
  # must not silently win over what the load wrote.
  test "reads its facts through the build" do
    mission = create(:game_mission, name: "Row Title", org_name: "Row Org")
    mission.build.update!(name: "Build Title", org_name: "Build Org", difficulty_mental_load: 6)

    assert_equal "Build Title", mission.reload.name
    assert_equal "Build Org", mission.org_name
    assert_equal 6, mission.difficulty_mental_load
  end

  test "#current_version narrows to the build we are on" do
    current = create(:game_mission)
    retired = create(:game_mission, :without_build, version: nil)

    assert_includes GameMission.current_version, current
    assert_not_includes GameMission.current_version, retired
    assert_includes GameMission.current_version(false), retired
  end

  test "#retired? is true for a contract the build no longer carries" do
    assert_not_predicate create(:game_mission), :retired?
    assert_predicate create(:game_mission, :without_build, version: nil), :retired?
  end

  # The one predicate the list and the detail page both apply. Resolved through
  # the build rather than the row, so a ptu read is not answered with live's.
  test ".released leaves out what the build is not offering" do
    offered = create(:game_mission)
    withheld = create(:game_mission, :unreleased)

    assert_includes GameMission.released, offered
    assert_not_includes GameMission.released, withheld
  end

  test ".released reads the build rather than the row" do
    mission = create(:game_mission)
    mission.build.update!(released: false)

    assert_not_includes GameMission.released, mission
  end

  # 74 of the 2,536 contracts have no name anywhere in the game data -- no
  # Title override, and a template whose displayString is uninitialised -- and
  # a row a reader cannot recognise is worse than no row.
  test ".named leaves out a contract the game never named" do
    named = create(:game_mission)
    nameless = create(:game_mission, name: nil)
    blank = create(:game_mission, name: "")

    assert_includes GameMission.named, named
    assert_not_includes GameMission.named, nameless
    assert_not_includes GameMission.named, blank
  end

  test ".from_org finds what one org offers" do
    foxwell = create(:game_mission, org_name: "Foxwell Enforcement")
    create(:game_mission, org_name: "Headhunters")

    assert_equal [foxwell], GameMission.from_org("Foxwell Enforcement").to_a
  end

  test ".rewarding finds a mission by what it pays" do
    paying = create(:game_mission, reward_kinds: %w[reputation item])
    create(:game_mission, reward_kinds: %w[reputation])

    assert_equal [paying], GameMission.rewarding("item").to_a
    assert_equal 2, GameMission.rewarding("reputation").count
  end

  # Asked with the pool refs the build carries rather than by joining
  # `blueprint_sources`, which holds its own copy of the mission name and would
  # have to match on a string 45 titles share between two orgs.
  test "#blueprints resolves the recipes the pools it names hand out" do
    pool_ref = Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, "pool-link")
    mission = create(:game_mission, blueprint_pool_refs: [pool_ref])
    blueprint = create(:blueprint)
    create(:blueprint_source, build: blueprint.build, pool_sc_ref: pool_ref)

    assert_equal [blueprint], mission.blueprints.to_a
  end

  test "#blueprints is empty for a mission that hands none out" do
    assert_empty create(:game_mission).blueprints
  end

  # A meta title is plain text, so the run-time spans have to come out -- but
  # not by deletion: dropping one leaves "Bounty:  wanted", and 902 of the 2472
  # titles carry one.
  test ".plain_text brackets a substitution rather than dropping it" do
    assert_equal "Bounty: [TargetName] wanted",
      GameMission.plain_text("Bounty: ~mission(TargetName) wanted")
  end

  # The part before the pipe is the noun; the rest names which of its fields
  # the game will substitute.
  test ".plain_text names the parameter rather than the field it reads" do
    assert_equal "Head to [Location]",
      GameMission.plain_text("Head to ~mission(Location|Address)")
  end

  # 3,567 opens across the localisation file, four of which never close.
  test ".plain_text takes the game's emphasis markup out" do
    assert_equal "Resupply the depot",
      GameMission.plain_text("Resupply <EM4>the depot</EM4>")
    assert_equal "Resupply the depot",
      GameMission.plain_text("Resupply <EM4>the depot")
  end

  test ".plain_text answers an absent string with nothing" do
    assert_nil GameMission.plain_text(nil)
    assert_nil GameMission.plain_text("")
  end

  # The row keeps its last build so a retired contract still resolves, and the
  # facts come off that build rather than off whatever the row happens to hold.
  test "falls back to the last build once the current one is gone" do
    mission = create(:game_mission, :without_build, version: nil, name: "Row Title")
    mission.builds.create!(
      environment: ScData::Source.environment, version: "0.0.1-live.1", name: "Old Title"
    )
    # Something else has to carry the configured build, or the one above is the
    # newest there is and the mission is not retired at all.
    create(:game_mission)

    assert_predicate mission.reload, :retired?
    assert_equal "Old Title", mission.name
  end
end
