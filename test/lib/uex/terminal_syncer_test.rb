# frozen_string_literal: true

require "test_helper"
require_relative "../../support/uex_fixtures"

module Uex
  class TerminalSyncerTest < ActiveSupport::TestCase
    include UexFixtures

    setup do
      Terminal.delete_all
    end

    test "#run creates one terminal per UEX commodity terminal" do
      result = sync

      assert_equal 3, result.created
      assert_equal [102, 104, 105], Terminal.order(:uex_id).pluck(:uex_id)
    end

    test "#run keeps two terminals sharing a name apart" do
      sync

      tdd = Terminal.where(name: "TDD - Trade and Development Division - Area 18").order(:uex_id)
      assert_equal ["TDD Area 18", "TDD Area 18 Annex"], tdd.map(&:nickname)
    end

    test "#run stores the location and facilities" do
      sync

      terminal = Terminal.find_by!(uex_id: 102)
      assert_equal "Stanton", terminal.star_system
      assert_equal "ArcCorp", terminal.planet
      assert_equal "ARC-L1 Wide Forest Station", terminal.space_station
      assert_nil terminal.city
      assert_equal 32, terminal.max_container_size
      assert terminal.has_freight_elevator
      assert terminal.available
      assert_nil terminal.contact_url
      assert_equal Time.zone.at(1766167856), terminal.source_updated_at
    end

    test "#run reads an unmeasured container size and an offline terminal" do
      sync

      annex = Terminal.find_by!(uex_id: 105)
      assert_nil annex.max_container_size
      assert_not annex.available
      assert annex.has_loading_dock
    end

    test "#run is idempotent" do
      sync
      result = sync

      assert_equal 0, result.created
      assert_equal 0, result.updated
    end

    test "#run retires a terminal UEX no longer lists instead of deleting it" do
      sync
      remaining = uex_fixture("terminals").reject { |row| row["id"] == 102 }

      result = sync(terminals: remaining)

      assert_equal 1, result.retired
      assert_not Terminal.find_by!(uex_id: 102).available
    end

    test "#run brings a retired terminal back when UEX lists it again" do
      create(:terminal, uex_id: 102, available: false)

      sync

      assert Terminal.find_by!(uex_id: 102).available
    end

    test "#run refuses a feed without commodity terminals" do
      create(:terminal, uex_id: 102)
      vehicles_only = uex_fixture("terminals").reject { |row| row["type"] == "commodity" }

      assert_raises(Uex::Error) { sync(terminals: vehicles_only) }
      assert Terminal.find_by!(uex_id: 102).available
    end

    private def sync(**overrides)
      Uex::TerminalSyncer.new(client: uex_client_stub(overrides)).run
    end
  end
end
