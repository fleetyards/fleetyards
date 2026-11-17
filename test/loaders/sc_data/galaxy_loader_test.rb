# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class GalaxyLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree

      setup do
        JumpTunnel.delete_all
        StarSystem.delete_all
      end

      def loader
        fixture_loader(::ScData::Loader::GalaxyLoader).tap do |loader|
          loader.define_singleton_method(:default_environment?) { true }
        end
      end

      test "#all loads every system and the tunnels between them" do
        loader.all

        stanton = StarSystem.find_by!(code: "STANTON")

        assert_equal 3, StarSystem.count
        assert_equal [49.534718, -2.6339645, 16.475292], stanton.position
        assert_equal ["UEE"], stanton.affiliations
        assert_equal %w[PYRO STANTON], StarSystem.where(in_game: true).order(:code).pluck(:code)
        assert_equal [%w[STANTON MAGNUS large], %w[STANTON PYRO medium]],
          JumpTunnel.includes(:entry_system, :exit_system).map { |tunnel| [tunnel.entry_system.code, tunnel.exit_system.code, tunnel.size] }.sort
      end

      test "#all removes a system and a tunnel the map no longer has" do
        gone = create(:star_system, code: "GONE")
        create(:jump_tunnel, entry_system: create(:star_system, code: "STANTON"), exit_system: gone)

        loader.all

        assert_nil StarSystem.find_by(code: "GONE")
        assert_equal 2, JumpTunnel.count
      end

      test "#all keeps a system's in-game flag when the parse cannot tell" do
        create(:star_system, code: "MAGNUS", in_game: true)
        galaxy_loader = loader
        galaxy_loader.define_singleton_method(:load_items) do |path|
          items = super(path)
          (path == "star_systems") ? items.map { |item| item.merge("in_game" => nil) } : items
        end

        galaxy_loader.all

        assert StarSystem.find_by!(code: "MAGNUS").in_game
      end

      test "#all keeps the tunnels when the parse has none" do
        create(:jump_tunnel, entry_system: create(:star_system, code: "STANTON"), exit_system: create(:star_system, code: "PYRO"))
        galaxy_loader = loader
        galaxy_loader.define_singleton_method(:load_items) { |path| (path == "jump_tunnels") ? [] : super(path) }

        galaxy_loader.all

        assert_equal 1, JumpTunnel.count
      end

      test "#all keeps what is there when the parse has no galaxy" do
        create(:star_system, code: "STANTON")

        empty_tree_loader(::ScData::Loader::GalaxyLoader).tap { |empty| empty.define_singleton_method(:default_environment?) { true } }.all

        assert_equal ["STANTON"], StarSystem.pluck(:code)
      end

      test "#all leaves the rows alone outside the default environment" do
        fixture_loader(::ScData::Loader::GalaxyLoader).tap { |other| other.define_singleton_method(:default_environment?) { false } }.all

        assert_equal 0, StarSystem.count
      end
    end
  end
end
