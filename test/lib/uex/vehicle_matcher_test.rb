# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class VehicleMatcherTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      @models = create_uex_fixture_models
      @vehicles = uex_fixture("vehicles").index_by { |vehicle| vehicle["id"] }
      @matcher = Uex::VehicleMatcher.new
    end

    test "matches on slug" do
      assert_equal @models[:slug_match].id, @matcher.match(@vehicles[1]).id
    end

    test "matches on name when the slug differs" do
      assert_equal "aegs-avenger-titan", @models[:name_match].slug
      assert_equal @models[:name_match].id, @matcher.match(@vehicles[2]).id
    end

    test "matches on name_full when neither slug nor name hit" do
      assert_equal @models[:name_full_match].id, @matcher.match(@vehicles[3]).id
    end

    test "matches via the explicit mapping" do
      assert_equal @models[:mapping_match].id, @matcher.match(@vehicles[4]).id
    end

    test "returns nil and records a miss for an unknown vehicle" do
      assert_nil @matcher.match(@vehicles[5])
      assert_equal ["vanduul-scythe"], @matcher.misses.map { |vehicle| vehicle["slug"] }
    end
  end
end
