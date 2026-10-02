# frozen_string_literal: true

require "test_helper"

module Uex
  class ShopLocationMatcherTest < ActiveSupport::TestCase
    setup do
      ItemPrice.delete_all
      Location.delete_all

      @stanton = place("Stanton System", kind: "system")
      @stanton_star = place("Stanton", parent: @stanton, kind: "star")
      @hurston = place("Hurston", parent: @stanton_star, kind: "planet")
      @everus = place("Everus Harbor", parent: @hurston)
      @point = place("HUR L1", parent: @hurston, sc_key: "Stanton1_L1")
      @green_glade = place("HUR-L1 Green Glade Station", parent: @point, sc_key: "RR_HUR_L1")
      @pyro_gateway = place("Pyro Gateway", parent: @stanton_star)

      @pyro = place("Pyro System", kind: "system")
      @pyro_star = place("Pyro", parent: @pyro, kind: "star")
      @pyro_side = place("Pyro Gateway", parent: @pyro_star)
    end

    test "#match reads the shop and the place it is at" do
      assert_equal ["Casaba Outlet", @everus.id], match("Casaba Outlet - Everus Harbor")
    end

    test "#match puts a shop at a Lagrange point in the rest stop there" do
      assert_equal ["Pharmacy", @green_glade.id], match("Pharmacy - HUR-L1")
    end

    test "#match tells a gateway apart by the system in brackets" do
      assert_equal @pyro_gateway.id, match("Casaba Outlet - Pyro Gateway (Stanton)").last
    end

    test "#match leaves a string that names no place alone" do
      assert_equal [nil, nil], match("Frostbite")
      assert_equal [nil, nil], match("Pharmacy - Orison General Hospital")
    end

    test ".relink links the prices at a shop to its place" do
      price = create(:item_price, item: create(:equipment), location: "Casaba Outlet - Everus Harbor", price_type: "sell", time_range: nil)

      assert_equal 1, ::Uex::ShopLocationMatcher.relink
      assert_equal [@everus.id, "Casaba Outlet"], price.reload.values_at(:location_id, :shop_name)
      assert_equal 0, ::Uex::ShopLocationMatcher.relink
    end

    private def match(value)
      ::Uex::ShopLocationMatcher.new.match(value)
    end

    private def place(name, parent: nil, kind: "station", sc_key: nil)
      create(:location, name:, parent:, kind:, system: parent&.system || (parent if parent&.kind == "system"),
        sc_key: sc_key || "#{name.parameterize(separator: "_")}_#{SecureRandom.hex(3)}")
    end
  end
end
