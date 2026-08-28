# frozen_string_literal: true

require "test_helper"

class ScData::UnlistedModelsTest < ActiveSupport::TestCase
  setup do
    @dir = Dir.mktmpdir
    @source = ScData::Source.new(version: "1.0.0", environment: "live")
    FileUtils.mkdir_p(models_path)
  end

  teardown do
    FileUtils.remove_entry(@dir)
  end

  def models_path
    File.join(@dir, "parsed", "live", "models")
  end

  def write_ship(identifier, name: identifier.titleize, mass: 1_000.0, crew: "1", ports: {})
    File.write(
      File.join(models_path, "#{identifier}.json"),
      JSON.dump(
        "name" => name, "mass" => mass, "min_crew" => crew, "hull_health" => 500.0,
        "loadout" => ports.map { |port, ref| {"name" => port, "ref" => ref} }
      )
    )
  end

  def run_detector
    ScData::UnlistedModels.new(@source, base_folder: @dir).run
  end

  test "reports a ship the export describes and the catalogue has no model for" do
    write_ship("drak_newhull", name: "Drake Newhull")

    result = run_detector

    assert_equal 1, result[:seen]
    entry = ScDataUnlistedModel.sole
    assert_equal "drak_newhull", entry.identifier
    assert_equal "Drake Newhull", entry.name
    assert_equal "DRAK", entry.manufacturer_code
    assert_equal "unrelated", entry.comparison
    assert_equal "1.0.0", entry.first_seen_version
  end

  test "leaves out a ship the catalogue already has" do
    create(:model, sc_key: "drak_caterpillar")
    write_ship("drak_caterpillar")

    assert_equal 0, run_detector[:seen]
    assert_empty ScDataUnlistedModel.all
  end

  # 733 of the 894 unlisted files in the live tree carry one of these.
  test "leaves out what the export names an NPC copy or a template" do
    %w[aegs_avenger_pu_ai_civ aegs_avenger_ai_template drak_cutlass_unmanned_ff rsi_x_wreck].each do |identifier|
      write_ship(identifier)
    end

    assert_equal 0, run_detector[:seen]
  end

  test "resolves the ship a variant extends, and how it compares" do
    create(:model, sc_key: "aegs_gladius", name: "Gladius")
    write_ship("aegs_gladius", ports: {"powerplant" => "a", "cooler" => "b"})
    write_ship("aegs_gladius_dunlevy", ports: {"powerplant" => "z", "cooler" => "b"})

    run_detector

    entry = ScDataUnlistedModel.find_by(identifier: "aegs_gladius_dunlevy")
    assert_equal "Gladius", entry.base_model.name
    assert_equal "refitted", entry.comparison
  end

  # A base ship can itself sit beneath another: `misc_freelancer` and
  # `misc_freelancer_dur` are both models, so a variant of the DUR must not
  # resolve to the plain Freelancer.
  test "resolves the most specific base ship, not the first that fits" do
    create(:model, sc_key: "aegs_gladius", name: "Gladius")
    create(:model, sc_key: "aegs_gladius_valiant", name: "Gladius Valiant")
    write_ship("aegs_gladius")
    write_ship("aegs_gladius_valiant")
    write_ship("aegs_gladius_valiant_showdown")

    run_detector

    entry = ScDataUnlistedModel.find_by(identifier: "aegs_gladius_valiant_showdown")
    assert_equal "Gladius Valiant", entry.base_model.name
  end

  test "calls a variant identical when every port carries the same item" do
    create(:model, sc_key: "aegs_gladius", name: "Gladius")
    write_ship("aegs_gladius", ports: {"powerplant" => "a"})
    write_ship("aegs_gladius_showdown", ports: {"powerplant" => "a"})

    run_detector

    assert_equal "identical", ScDataUnlistedModel.find_by(identifier: "aegs_gladius_showdown").comparison
  end

  test "calls a variant structural when a port or a number moved" do
    create(:model, sc_key: "argo_atls", name: "ATLS")
    write_ship("argo_atls", mass: 1_440.0, ports: {"seat" => "a"})
    write_ship("argo_atls_ikti", mass: 1_800.0, ports: {"seat" => "a", "radar" => "b"})

    run_detector

    assert_equal "structural", ScDataUnlistedModel.find_by(identifier: "argo_atls_ikti").comparison
  end

  # What you earn from Wikelo's Emporium or PYAM is the base ship carrying that
  # fitting, not a second ship. The vendor is written in the display name rather
  # than the identifier.
  test "leaves out a loadout an in-game vendor sells on a hull we already have" do
    create(:model, sc_key: "mrai_guardian", name: "Guardian")
    write_ship("mrai_guardian")
    write_ship("mrai_guardian_military", name: "Mirai Guardian Wikelo War Special")
    write_ship("drak_corsair_exec_military", name: "Corsair PYAM Exec")
    create(:model, sc_key: "drak_corsair", name: "Corsair")
    write_ship("drak_corsair")

    result = run_detector

    assert_equal 0, result[:seen]
    assert_empty ScDataUnlistedModel.all
  end

  # The safety valve: a vendor selling a hull the catalogue does not have has no
  # base ship, and has to stay reported.
  test "still reports a vendor ship with no base ship in the catalogue" do
    write_ship("krig_newhull_collector_mod", name: "Kruger Newhull Wikelo Special")

    assert_equal 1, run_detector[:seen]
    assert_equal "krig_newhull_collector_mod", ScDataUnlistedModel.sole.identifier
  end

  test "a row the vendor rule now covers stops being reported" do
    create(:model, sc_key: "mrai_guardian", name: "Guardian")
    write_ship("mrai_guardian")
    write_ship("mrai_guardian_military", name: "Mirai Guardian")
    run_detector

    assert_equal 1, ScDataUnlistedModel.count

    write_ship("mrai_guardian_military", name: "Mirai Guardian Wikelo War Special")

    assert_empty run_detector[:undecided]
    assert_empty ScDataUnlistedModel.all
  end

  # A decision already made is the record of it, whatever a later rule says.
  test "a decided row survives a rule that would now exclude it" do
    create(:model, sc_key: "mrai_guardian", name: "Guardian")
    write_ship("mrai_guardian")
    write_ship("mrai_guardian_military", name: "Mirai Guardian")
    run_detector
    ScDataUnlistedModel.sole.decide!("ignored")

    write_ship("mrai_guardian_military", name: "Mirai Guardian Wikelo War Special")
    run_detector

    assert_equal 1, ScDataUnlistedModel.count
    assert_equal "ignored", ScDataUnlistedModel.sole.decision
  end

  # Every unresolved identifier in the live tree today is a world object -- an
  # orbital sentry, a comm probe, a satellite.
  test "records no manufacturer for a prefix no ship in the catalogue uses" do
    write_ship("orbital_sentry_pu_uee", name: "Orbital Sentry")

    run_detector

    entry = ScDataUnlistedModel.sole
    assert_nil entry.manufacturer_code
    assert_predicate entry, :unknown_manufacturer?
  end

  test "seeing the same ship again neither duplicates it nor makes it new" do
    write_ship("drak_newhull")
    run_detector

    later = ScData::UnlistedModels.new(
      ScData::Source.new(version: "1.0.1", environment: "live"), base_folder: @dir
    )
    # The tree is read per environment, so the newer build reads the same files.
    result = later.run

    entry = ScDataUnlistedModel.sole
    assert_equal "1.0.0", entry.first_seen_version
    assert_equal "1.0.1", entry.last_seen_version
    assert_empty result[:new], "a ship seen in an earlier build is not new"
    assert_equal 1, result[:undecided].size
  end

  test "a decided ship stops being reported" do
    write_ship("drak_newhull")
    run_detector

    ScDataUnlistedModel.sole.update!(decision: "ignored", decided_at: Time.current)

    result = run_detector
    assert_empty result[:undecided]
    assert_equal 1, ScDataUnlistedModel.count
  end

  test "refreshes the base ship when the catalogue gains one" do
    write_ship("aegs_gladius", ports: {"powerplant" => "a"})
    write_ship("aegs_gladius_dunlevy", ports: {"powerplant" => "a"})
    run_detector

    assert_nil ScDataUnlistedModel.find_by(identifier: "aegs_gladius_dunlevy").base_model

    create(:model, sc_key: "aegs_gladius", name: "Gladius")
    run_detector

    assert_equal "Gladius", ScDataUnlistedModel.find_by(identifier: "aegs_gladius_dunlevy").base_model.name
  end

  test "only a new ship makes the report actionable" do
    write_ship("drak_newhull")
    result = run_detector

    assert ScData::UnlistedModels.actionable?(result)
    assert_includes ScData::UnlistedModels.report_body(result, @source), "drak_newhull"

    ScDataUnlistedModel.sole.update!(decision: "ignored", decided_at: Time.current)

    assert_not ScData::UnlistedModels.actionable?(run_detector)
  end
end
