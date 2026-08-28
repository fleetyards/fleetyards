# frozen_string_literal: true

require "test_helper"

class ScData::ManufacturerMappingTest < ActiveSupport::TestCase
  test "resolves a manufacturer from the identifier prefix" do
    assert_equal "DRAK", ScData::ManufacturerMapping.code_for("drak_caterpillar")
    assert_equal "AEGS", ScData::ManufacturerMapping.code_for("aegs_gladius_dunlevy")
    assert_equal "RSI", ScData::ManufacturerMapping.code_for("rsi_apollo_medivac_tier_1")
  end

  # Two prefixes do not spell their own code, which is the whole reason a table
  # exists rather than an upcase of the prefix.
  test "resolves the two prefixes that do not spell their own code" do
    assert_equal "XNAA", ScData::ManufacturerMapping.code_for("xian_scout")
    assert_equal "GREY", ScData::ManufacturerMapping.code_for("glsn_shiv")
  end

  # Mirai is MISC's sub-brand, so the Fury files under `misc_`.
  test "a family wins over the prefix" do
    assert_equal "MRAI", ScData::ManufacturerMapping.code_for("misc_fury")
    assert_equal "MISC", ScData::ManufacturerMapping.code_for("misc_freelancer")
  end

  test "a family covers the variants beneath it" do
    assert_equal "MRAI", ScData::ManufacturerMapping.code_for("misc_fury_lx")
    assert_equal "MRAI", ScData::ManufacturerMapping.code_for("misc_fury_miru")
    assert_equal "MRAI", ScData::ManufacturerMapping.code_for("misc_razor_ex")
  end

  # Esperia builds replicas of Vanduul hulls under the Vanduul prefix -- but the
  # Scythe under that same prefix really is Vanduul.
  test "a family does not capture its prefix siblings" do
    assert_equal "ESPR", ScData::ManufacturerMapping.code_for("vncl_glaive")
    assert_equal "VNCL", ScData::ManufacturerMapping.code_for("vncl_scythe")
  end

  test "a prefix the family only resembles is not a match" do
    assert_equal "MISC", ScData::ManufacturerMapping.code_for("misc_furyx")
  end

  # An unknown prefix is a finding, not a failure: the export has introduced a
  # company, or the file is not a ship at all. Every unresolved identifier in the
  # live tree is a world object -- orbital sentries, comm probes, a satellite.
  test "an unknown prefix resolves to nothing rather than a guess" do
    assert_nil ScData::ManufacturerMapping.code_for("orbital_sentry_pu_uee")
    assert_nil ScData::ManufacturerMapping.code_for("probe_comms_1_a")
    assert_nil ScData::ManufacturerMapping.code_for("newco_wonderfulship")
  end

  test "handles a blank identifier" do
    assert_nil ScData::ManufacturerMapping.code_for(nil)
    assert_nil ScData::ManufacturerMapping.code_for("")
  end

  test ".for returns the manufacturer itself" do
    manufacturer = create(:manufacturer, code: "DRAK")

    assert_equal manufacturer, ScData::ManufacturerMapping.for("drak_caterpillar")
  end

  test ".for returns nothing for a code the catalogue does not carry" do
    assert_nil ScData::ManufacturerMapping.for("banu_defender")
  end

  # A family whose code matches what its prefix already gives is dead weight, and
  # one whose prefix is missing from the table would resolve by accident.
  test "every family earns its entry" do
    ScData::ManufacturerMapping::FAMILIES.each do |stem, code|
      prefix = stem.split("_").first

      assert_includes ScData::ManufacturerMapping::PREFIXES, prefix,
        "#{stem} names a prefix the table does not carry"
      assert_not_equal ScData::ManufacturerMapping::PREFIXES[prefix], code,
        "#{stem} resolves to what its prefix already gives"
    end
  end

  # The lookup takes the first stem that matches, which is only unambiguous while
  # no stem sits beneath another. If that ever stops being true, the lookup needs
  # an order before the new entry can be trusted.
  test "no family stem sits beneath another" do
    stems = ScData::ManufacturerMapping::FAMILIES.keys

    stems.combination(2).each do |a, b|
      assert_not a.start_with?("#{b}_"), "#{a} sits beneath #{b}"
      assert_not b.start_with?("#{a}_"), "#{b} sits beneath #{a}"
    end
  end
end
