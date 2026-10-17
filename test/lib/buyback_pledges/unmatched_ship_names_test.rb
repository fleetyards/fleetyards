# frozen_string_literal: true

require "test_helper"

class BuybackPledges::UnmatchedShipNamesTest < ActiveSupport::TestCase
  setup do
    create(:model, name: "C2 Hercules", rsi_name: "C2 Hercules")
    create(:model, name: "Cutter", rsi_name: "Cutter")
    @user = create(:user)
  end

  def buyback(**attributes)
    BuybackPledge.create!(user: @user, rsi_pledge_id: SecureRandom.random_number(10**8).to_s, kind: "ship",
      name: "Standalone Ship - Cutter", **attributes)
  end

  test "lists the names no model or RSI alias matches, most common first" do
    buyback(kind: "package", contained: "3 ships and 4 items",
      ship_names: ["HERCULES STARLIFTER C2", "Starlifter Hercules C2", "Cutter"])
    buyback(contained: "Cutter Scout and 2 items")
    buyback(contained: "Cutter Scout and 2 items")
    buyback(contained: "Cutter and 2 items")

    assert_equal [["Cutter Scout", 2], ["Starlifter Hercules C2", 1]], BuybackPledges::UnmatchedShipNames.new.run
  end

  test "skips upgraded pledges, which list the ship they were upgraded to" do
    buyback(upgraded: true, contained: "Mercury Star Runner and 3 items", ship_names: ["Mercury Star Runner"])

    assert_empty BuybackPledges::UnmatchedShipNames.new.run
  end

  test "matches the names RSI gives ships it renamed or edition-named" do
    create(:model, name: "Constellation Mk IV Phoenix", rsi_name: "Constellation Mk IV Phoenix")
    create(:model, name: "X1 Force", rsi_name: "X1 Force")
    buyback(contained: "Constellation Phoenix and 2 items")
    buyback(contained: "X1 - FORCE and 2 items")
    buyback(contained: "Cutter and Lifetime Insurance")

    assert_empty BuybackPledges::UnmatchedShipNames.new.run
  end

  test "skips the contents of anything but a ship pledge" do
    buyback(kind: "other", contained: "Pulse Flight Jacket")
    buyback(kind: "ship", contained: "2 ships and 2 items")

    assert_empty BuybackPledges::UnmatchedShipNames.new.run
  end
end
