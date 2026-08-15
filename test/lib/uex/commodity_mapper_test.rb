# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class CommodityMapperTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      Commodity.delete_all
      @commodities = create_uex_fixture_commodities
    end

    test "#run writes the UEX id and code onto the commodities it resolves" do
      result = Uex::CommodityMapper.new(client: uex_client_stub).run

      assert_equal 3, result.mapped
      assert_equal 0, result.updated

      assert_equal [33, "GOLD"], @commodities[:name_match].reload.then { |c| [c.uex_id, c.uex_code] }
      assert_equal [24, "AGRIORE"], @commodities[:punctuated_match].reload.then { |c| [c.uex_id, c.uex_code] }
      assert_equal [137, "LASTA"], @commodities[:mapping_match].reload.then { |c| [c.uex_id, c.uex_code] }
    end

    test "#run leaves a commodity UEX has no row for unmapped" do
      result = Uex::CommodityMapper.new(client: uex_client_stub).run

      assert_nil @commodities[:near_neighbour].reload.uex_id
      assert_equal ["Organs"], result.unmapped.map(&:name)
    end

    test "#run reports UEX rows that resolve to nothing of ours" do
      result = Uex::CommodityMapper.new(client: uex_client_stub).run

      assert_equal ["Aslarite", "Lunes", "Organics"], result.unmatched.map { |row| row["name"] }.sort
    end

    test "#run counts a changed mapping as an update rather than a new one" do
      @commodities[:name_match].update!(uex_id: 33, uex_code: "OLD")

      result = Uex::CommodityMapper.new(client: uex_client_stub).run

      assert_equal 1, result.updated
      assert_equal "GOLD", @commodities[:name_match].reload.uex_code
    end

    test "#run is idempotent" do
      Uex::CommodityMapper.new(client: uex_client_stub).run
      result = Uex::CommodityMapper.new(client: uex_client_stub).run

      assert_equal 0, result.mapped
      assert_equal 0, result.updated
    end

    test "#run reports the second of two UEX rows claiming one commodity" do
      duplicate = uex_fixture("commodities") + [{"id" => 1001, "name" => "gold", "code" => "DUPE"}]

      result = Uex::CommodityMapper.new(client: uex_client_stub(commodities: duplicate)).run

      assert_equal 33, @commodities[:name_match].reload.uex_id
      assert_includes result.unmatched.map { |row| row["id"] }, 1001
    end

    test "#run refuses an empty snapshot rather than reporting everything unmapped" do
      error = assert_raises(Uex::Error) do
        Uex::CommodityMapper.new(client: uex_client_stub(commodities: [])).run
      end

      assert_match(/refusing to map against an empty snapshot/, error.message)
      assert_nil @commodities[:name_match].reload.uex_id
    end

    test ".github_issue_body lists the unmapped commodities without volatile counts" do
      result = Uex::CommodityMapper.new(client: uex_client_stub).run
      body = Uex::CommodityMapper.github_issue_body(result)

      assert_match(/Commodities Without a UEX Mapping \(1\)/, body)
      assert_match(/\*\*Organs\*\* — `items_commodities_organs`/, body)
      assert_no_match(/mapped=/, body)
    end
  end
end
