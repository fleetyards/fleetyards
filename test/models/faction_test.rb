# frozen_string_literal: true

require "test_helper"

class FactionTest < ActiveSupport::TestCase
  test ".slug_for_key drops the prefix and the alignment every key repeats" do
    assert_equal "redwindlinehaul", Faction.slug_for_key("factionreputation_lawful_redwindlinehaul")
    assert_equal "tarpits", Faction.slug_for_key("factionreputation_unlawful_tarpits")
    assert_equal "wikelo", Faction.slug_for_key("factionreputation_wikelo")
    assert_nil Faction.slug_for_key(nil)
  end

  test "#ladder_awards sums what completing its released missions adds to each ladder" do
    faction = create(:faction)

    reward(faction, amount: 100)
    reward(faction, amount: 400)
    reward(faction, amount: 800, released: false)
    reward(faction, amount: -50)
    reward(faction, amount: 900, outcome: "not_completed")
    reward(create(:faction), amount: 5000)

    assert_equal({"reputationscope_hauling" => {missions: 2, min: 100, max: 400}}, faction.ladder_awards)
  end

  test "#mission_count counts its released missions" do
    faction = create(:faction)

    create(:game_mission, org_key: faction.sc_key)
    create(:game_mission, org_key: faction.sc_key, released: false)

    assert_equal 1, faction.mission_count
    assert_equal({faction.sc_key => 1}, Faction.mission_counts.slice(faction.sc_key))
  end

  private def reward(faction, amount:, outcome: "completed", released: true)
    mission = create(:game_mission, org_key: "factionreputation_lawful_other", released:)

    create(:game_mission_reward, build: mission.build, amount:, outcome:,
      org_key: faction.sc_key, ladder_key: "reputationscope_hauling", ladder_name: "Hauling")
  end
end
