# frozen_string_literal: true

require "test_helper"

module Uex
  class TerminalLocationMatcherTest < ActiveSupport::TestCase
    setup do
      Terminal.delete_all
      Location.delete_all

      @stanton = place("Stanton System", kind: "system")
      @stanton_star = place("Stanton", parent: @stanton, kind: "star")
      @arccorp = place("ArcCorp", parent: @stanton_star, kind: "planet")
      @crusader = place("Crusader", parent: @stanton_star, kind: "planet")
      @yela = place("Yela", parent: @crusader, kind: "moon")
      @daymar = place("Daymar", parent: @crusader, kind: "moon")
      @area18 = place("Area18", parent: @arccorp, kind: "city")
      @pyro_gateway = place("Pyro Gateway", parent: @stanton_star)

      @pyro = place("Pyro System", kind: "system")
      @pyro_star = place("Pyro", parent: @pyro, kind: "star")
      @checkmate = place("Checkmate", parent: @pyro_star)
      @stanton_gateway = place("Stanton Gateway", parent: @pyro_star)
    end

    test "#match finds a place by name within the terminal's system" do
      assert_equal @area18.id, match(city: "Area 18", planet: "ArcCorp")
    end

    test "#match reads past the system UEX writes in brackets" do
      assert_equal @pyro_gateway.id, match(space_station: "Pyro Gateway (Stanton)")
      assert_equal @stanton_gateway.id, match(star_system: "Pyro", space_station: "Stanton Gateway (Pyro)")
    end

    test "#match reads past a trailing Station" do
      assert_equal @checkmate.id, match(star_system: "Pyro", space_station: "Checkmate Station")
    end

    test "#match tells a shared name apart by the moon UEX names" do
      place("Outpost 54", parent: @yela, kind: "outpost")
      daymar_outpost = place("Outpost 54", parent: @daymar, kind: "outpost")

      assert_equal daymar_outpost.id, match(outpost: "Outpost 54", moon: "Daymar", planet: "Crusader")
    end

    test "#match takes a name UEX shortened" do
      deakins = place("Deakins Research Outpost", parent: @yela, kind: "outpost")

      assert_equal deakins.id, match(outpost: "Deakins Research", moon: "Yela", planet: "Crusader")
    end

    test "#match leaves a terminal at a place the starmap does not carry unlinked" do
      assert_nil match(space_station: "Port Olisar", planet: "Crusader")
      assert_nil match(star_system: nil, space_station: "Pyro Gateway (Stanton)")
    end

    test ".relink links terminals synced before their places loaded" do
      terminal = create(:terminal, star_system: "Stanton", planet: "ArcCorp", city: "Area 18", space_station: nil, outpost: nil, moon: nil)
      terminal.update_columns(location_id: nil)

      assert_equal 1, ::Uex::TerminalLocationMatcher.relink
      assert_equal @area18.id, terminal.reload.location_id
      assert_equal 0, ::Uex::TerminalLocationMatcher.relink
    end

    private def match(star_system: "Stanton", **levels)
      terminal = Terminal.new(star_system:, **levels)

      ::Uex::TerminalLocationMatcher.new.match(terminal)
    end

    private def place(name, parent: nil, kind: "station")
      create(:location, name:, parent:, kind:, sc_key: "#{name.parameterize(separator: "_")}_#{SecureRandom.hex(3)}")
    end
  end
end
